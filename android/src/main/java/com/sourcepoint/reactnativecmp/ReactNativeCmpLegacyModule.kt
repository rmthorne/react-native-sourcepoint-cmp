package com.sourcepoint.reactnativecmp

import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.sourcepoint.cmplibrary.SpClient
import com.sourcepoint.cmplibrary.creation.delegate.spConsentLibLazy
import com.sourcepoint.cmplibrary.model.exposed.SpCampaigns
import com.sourcepoint.cmplibrary.model.exposed.SpConfig
import com.sourcepoint.cmplibrary.exception.CampaignType
import com.sourcepoint.cmplibrary.model.exposed.SPConsents
import com.sourcepoint.reactnativecmp.arguments.Arguments

class ReactNativeCmpLegacyModule(reactContext: ReactApplicationContext) : 
    ReactContextBaseJavaModule(reactContext), ActivityEventListener {

    companion object {
        const val NAME = "ReactNativeCmp"
    }

    private val spConsentLib by spConsentLibLazy {
        activity = currentActivity
        spClient = LocalClient()
        spConfig = SpConfig(
            accountId = 22,
            propertyId = 7639,
            propertyName = "tcfv2.mobile.webview",
            messLanguage = com.sourcepoint.cmplibrary.model.MessageLanguage.ENGLISH,
            campaignsEnv = com.sourcepoint.cmplibrary.model.exposed.SPCampaignEnv.PUBLIC,
            campaigns = SpCampaigns()
        )
    }

    private var builtConfig: SpConfig? = null

    init {
        reactContext.addActivityEventListener(this)
    }

    override fun getName(): String = NAME

    inner class LocalClient : SpClient {
        override fun onUIFinished(view: android.view.View) {
            sendEvent("onSPUIFinished", null)
        }

        override fun onUIReady(view: android.view.View) {
            sendEvent("onSPUIReady", null)
        }

        override fun onAction(view: android.view.View, consentAction: com.sourcepoint.cmplibrary.model.ConsentAction): com.sourcepoint.cmplibrary.model.ConsentAction {
            val actionJson = Arguments.getActionMap(consentAction)
            sendEvent("internalOnAction", Arguments.writeableMapToJson(actionJson))
            return consentAction
        }

        override fun onSpFinished(sPConsents: SPConsents) {
            sendEvent("onFinished", null)
        }

        override fun onConsentReady(consent: SPConsents) {}

        override fun onError(error: Throwable) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", error.message ?: "Unknown error")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun build(
        accountId: Double,
        propertyId: Double,
        propertyName: String,
        campaigns: ReadableMap,
        options: ReadableMap?
    ) {
        try {
            val spConfig = Arguments.getConfig(
                accountId = accountId.toInt(),
                propertyId = propertyId.toInt(),
                propertyName = propertyName,
                campaigns = campaigns,
                options = options
            )
            
            builtConfig = spConfig
            spConsentLib.spConfig = spConfig
            
            currentActivity?.let { activity ->
                spConsentLib.activity = activity
            }
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Build failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun loadMessage(params: ReadableMap?) {
        try {
            val authId = params?.getString("authId")
            if (authId != null) {
                spConsentLib.loadMessage(authId)
            } else {
                spConsentLib.loadMessage()
            }
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Load message failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun getUserData(promise: Promise) {
        try {
            val userData = spConsentLib.userData
            val userDataMap = Arguments.getUserDataMap(userData)
            promise.resolve(userDataMap)
        } catch (e: Exception) {
            promise.reject("GET_USER_DATA_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun clearLocalData() {
        try {
            spConsentLib.clearAllData()
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Clear data failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun loadGDPRPrivacyManager(pmId: String) {
        try {
            spConsentLib.loadPrivacyManager(pmId, CampaignType.GDPR)
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Load GDPR PM failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun loadUSNatPrivacyManager(pmId: String) {
        try {
            spConsentLib.loadPrivacyManager(pmId, CampaignType.USNAT)
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Load USNat PM failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun loadGlobalCmpPrivacyManager(pmId: String) {
        try {
            spConsentLib.loadPrivacyManager(pmId, CampaignType.GLOBALCMP)
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Load Global CMP PM failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun loadPreferenceCenter(id: String) {
        try {
            spConsentLib.loadPreferenceCenter(id)
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Load preference center failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun dismissMessage() {
        try {
            spConsentLib.dismissMessage()
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Dismiss message failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun postCustomConsentGDPR(
        vendors: ReadableArray,
        categories: ReadableArray,
        legIntCategories: ReadableArray,
        callback: Callback
    ) {
        try {
            val vendorsList = Arguments.readableArrayToStringList(vendors)
            val categoriesList = Arguments.readableArrayToStringList(categories)
            val legIntCategoriesList = Arguments.readableArrayToStringList(legIntCategories)
            
            spConsentLib.postCustomConsent(
                vendors = vendorsList,
                categories = categoriesList,
                legIntCategories = legIntCategoriesList,
                campaignType = CampaignType.GDPR,
                onSuccess = { spConsents ->
                    val gdprConsent = Arguments.getGdprConsentMap(spConsents)
                    callback.invoke(gdprConsent)
                },
                onError = { error ->
                    val errorMap = WritableNativeMap()
                    errorMap.putString("description", error.message ?: "Custom consent failed")
                    sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
                }
            )
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Custom consent failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun postDeleteCustomConsentGDPR(
        vendors: ReadableArray,
        categories: ReadableArray,
        legIntCategories: ReadableArray,
        callback: Callback
    ) {
        try {
            val vendorsList = Arguments.readableArrayToStringList(vendors)
            val categoriesList = Arguments.readableArrayToStringList(categories)
            val legIntCategoriesList = Arguments.readableArrayToStringList(legIntCategories)
            
            spConsentLib.deleteCustomConsent(
                vendors = vendorsList,
                categories = categoriesList,
                legIntCategories = legIntCategoriesList,
                campaignType = CampaignType.GDPR,
                onSuccess = { spConsents ->
                    val gdprConsent = Arguments.getGdprConsentMap(spConsents)
                    callback.invoke(gdprConsent)
                },
                onError = { error ->
                    val errorMap = WritableNativeMap()
                    errorMap.putString("description", error.message ?: "Delete custom consent failed")
                    sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
                }
            )
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Delete custom consent failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    @ReactMethod
    fun rejectAll(campaignType: String) {
        try {
            val campaign = when (campaignType.lowercase()) {
                "gdpr" -> CampaignType.GDPR
                "usnat" -> CampaignType.USNAT
                "preferences" -> CampaignType.PREFERENCES
                "globalcmp" -> CampaignType.GLOBALCMP
                else -> throw IllegalArgumentException("Invalid campaign type: $campaignType")
            }
            
            spConsentLib.rejectAll(campaign)
        } catch (e: Exception) {
            val errorMap = WritableNativeMap()
            errorMap.putString("description", e.message ?: "Reject all failed")
            sendEvent("internalOnError", Arguments.writeableMapToJson(errorMap))
        }
    }

    private fun sendEvent(eventName: String, params: Any?) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }

    override fun onActivityResult(
        activity: android.app.Activity?,
        requestCode: Int,
        resultCode: Int,
        data: android.content.Intent?
    ) {
        // Handle activity results if needed
    }

    override fun onNewIntent(intent: android.content.Intent?) {
        // Handle new intents if needed
    }
}