package com.sourcepoint.reactnativecmp

import android.view.View
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.sourcepoint.cmplibrary.SpClient
import com.sourcepoint.cmplibrary.SpConsentLib
import com.sourcepoint.cmplibrary.creation.ConfigOption.SUPPORT_LEGACY_USPSTRING
import com.sourcepoint.cmplibrary.creation.SpConfigDataBuilder
import com.sourcepoint.cmplibrary.creation.makeConsentLib
import com.sourcepoint.cmplibrary.data.network.util.CampaignType.*
import com.sourcepoint.cmplibrary.model.ConsentAction
import com.sourcepoint.cmplibrary.model.exposed.SPConsents
import com.sourcepoint.cmplibrary.util.clearAllData
import com.sourcepoint.cmplibrary.util.userConsents
import com.sourcepoint.reactnativecmp.arguments.toList
import com.sourcepoint.reactnativecmp.consents.RNSPGDPRConsent
import com.sourcepoint.reactnativecmp.consents.RNSPUserData
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class ReactNativeCmpLegacyModule(reactContext: ReactApplicationContext) : 
    ReactContextBaseJavaModule(reactContext), ActivityEventListener, SpClient {

    companion object {
        const val NAME = "ReactNativeCmp"
    }

    private var spConsentLib: SpConsentLib? = null

    init {
        reactContext.addActivityEventListener(this)
    }

    override fun getName(): String = NAME

    private fun runOnMainThread(runnable: () -> Unit) {
        reactApplicationContext.runOnUiQueueThread(runnable)
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
            val convertedCampaigns = campaigns.SPCampaigns()
            val parsedOptions = com.sourcepoint.reactnativecmp.arguments.BuildOptions(options)
            val config = SpConfigDataBuilder().apply {
                addAccountId(accountId.toInt())
                addPropertyName(propertyName)
                addPropertyId(propertyId.toInt())
                addMessageTimeout(parsedOptions.messageTimeoutInMilliseconds)
                addMessageLanguage(parsedOptions.language)
                convertedCampaigns.gdpr?.let {
                    addCampaign(campaignType = GDPR, params = it.targetingParams, groupPmId = it.groupPmId)
                }
                convertedCampaigns.usnat?.let {
                    addCampaign(
                        campaignType = USNAT,
                        params = it.targetingParams,
                        groupPmId = it.groupPmId,
                        configParams = if(it.supportLegacyUSPString) setOf(SUPPORT_LEGACY_USPSTRING) else emptySet()
                    )
                }
                convertedCampaigns.preferences?.let {
                    addCampaign(campaignType = PREFERENCES, params = it.targetingParams, groupPmId = it.groupPmId)
                }
                convertedCampaigns.globalcmp?.let {
                    addCampaign(campaignType = GLOBALCMP, params = it.targetingParams, groupPmId = it.groupPmId)
                }
            }.build()

            reactApplicationContext.currentActivity?.let {
                spConsentLib = makeConsentLib(config, it, this, parsedOptions.androidDismissMessageOnBackPress)
            } ?: run {
                onError(Error("No activity found when building the SDK"))
            }
        } catch (e: Exception) {
            onError(e)
        }
    }

    @ReactMethod
    fun loadMessage(params: ReadableMap?) {
        try {
            val authId = params?.getString("authId")
            runOnMainThread {
                spConsentLib?.loadMessage(authId = authId, cmpViewId = View.generateViewId())
            }
        } catch (e: Exception) {
            onError(e)
        }
    }

    @ReactMethod
    fun getUserData(promise: Promise) {
        try {
            promise.resolve(userConsentsToWriteableMap(userConsents(reactApplicationContext)))
        } catch (e: Exception) {
            promise.reject("GET_USER_DATA_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun clearLocalData() {
        clearAllData(reactApplicationContext)
    }

    @ReactMethod
    fun loadGDPRPrivacyManager(pmId: String) {
        runOnMainThread { spConsentLib?.loadPrivacyManager(pmId, GDPR) }
    }

    @ReactMethod
    fun loadUSNatPrivacyManager(pmId: String) {
        runOnMainThread { spConsentLib?.loadPrivacyManager(pmId, USNAT) }
    }

    @ReactMethod
    fun loadGlobalCmpPrivacyManager(pmId: String) {
        runOnMainThread { spConsentLib?.loadPrivacyManager(pmId, GLOBALCMP) }
    }

    @ReactMethod
    fun loadPreferenceCenter(id: String) {
        runOnMainThread { spConsentLib?.loadPrivacyManager(id, PREFERENCES) }
    }

    @ReactMethod
    fun dismissMessage() {
        runOnMainThread { spConsentLib?.dismissMessage() }
    }

    @ReactMethod
    fun postCustomConsentGDPR(
        vendors: ReadableArray,
        categories: ReadableArray,
        legIntCategories: ReadableArray,
        callback: Callback
    ) {
        runOnMainThread {
            spConsentLib?.customConsentGDPR(
                vendors.toList(),
                categories.toList(),
                legIntCategories.toList(),
                success = { consents ->
                    if (consents?.gdpr != null) {
                        callback.invoke(RNSPGDPRConsent(consents.gdpr!!.consent).toRN())
                    } else {
                        callback.invoke(RNSPGDPRConsent(applies = true).toRN())
                    }
                }
            )
        }
    }

    @ReactMethod
    fun postDeleteCustomConsentGDPR(
        vendors: ReadableArray,
        categories: ReadableArray,
        legIntCategories: ReadableArray,
        callback: Callback
    ) {
        runOnMainThread {
            spConsentLib?.deleteCustomConsentTo(
                vendors.toList(),
                categories.toList(),
                legIntCategories.toList(),
                success = { consents ->
                    if (consents?.gdpr != null) {
                        callback.invoke(RNSPGDPRConsent(consents.gdpr!!.consent).toRN())
                    } else {
                        callback.invoke(RNSPGDPRConsent(applies = true).toRN())
                    }
                }
            )
        }
    }

    @ReactMethod
    fun rejectAll(campaignType: String) {
        runOnMainThread {
            spConsentLib?.rejectAll(campaignTypeFrom(campaignType))
        }
    }

    // SpClient implementation
    override fun onAction(view: View, consentAction: ConsentAction): ConsentAction {
        emitInternalOnAction(Json.encodeToString(mapOf(
            "actionType" to RNSourcepointActionType.from(consentAction.actionType).name,
            "customActionId" to consentAction.customActionId
        )))
        return consentAction
    }

    override fun onConsentReady(consent: SPConsents) {}

    override fun onError(error: Throwable) {
        emitInternalOnError(Json.encodeToString(mapOf("description" to error.message)))
    }

    override fun onNoIntentActivitiesFound(url: String) {}

    override fun onSpFinished(sPConsents: SPConsents) {
        emitOnFinished()
    }

    override fun onMessageInactivityTimeout() {
        emitOnMessageInactivityTimeout()
    }

    override fun onUIFinished(view: View) {
        spConsentLib?.removeView(view)
        emitOnSPUIFinished()
    }

    override fun onUIReady(view: View) {
        spConsentLib?.showView(view)
        emitOnSPUIReady()
    }

    // ActivityEventListener implementation
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

    // Event emitters
    private fun emitInternalOnAction(params: String) {
        sendEvent("internalOnAction", params)
    }

    private fun emitInternalOnError(params: String) {
        sendEvent("internalOnError", params)
    }

    private fun emitOnFinished() {
        sendEvent("onFinished", null)
    }

    private fun emitOnMessageInactivityTimeout() {
        sendEvent("onMessageInactivityTimeout", null)
    }

    private fun emitOnSPUIFinished() {
        sendEvent("onSPUIFinished", null)
    }

    private fun emitOnSPUIReady() {
        sendEvent("onSPUIReady", null)
    }

    private fun sendEvent(eventName: String, params: Any?) {
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }

    private fun userConsentsToWriteableMap(consents: SPConsents) = RNSPUserData(consents).toRN()
}