package com.sourcepoint.reactnativecmp

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import java.util.HashMap

class ReactNativeCmpPackage : BaseReactPackage() {
  companion object {
    private fun isTurboModuleEnabled(reactContext: ReactApplicationContext): Boolean {
      return try {
        // Check if TurboModules are enabled by looking for the TurboModuleRegistry
        Class.forName("com.facebook.react.turbomodule.core.TurboModuleRegistry")
        val turboModuleEnabledProperty = reactContext.catalystInstance?.let { catalystInstance ->
          // Try to access TurboModule-specific methods or properties
          catalystInstance.javaClass.methods.any { method ->
            method.name.contains("turbo", ignoreCase = true)
          }
        } ?: false
        turboModuleEnabledProperty
      } catch (e: Exception) {
        false
      }
    }
  }

  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return if (name == ReactNativeCmpModule.NAME || name == ReactNativeCmpLegacyModule.NAME) {
      if (isTurboModuleEnabled(reactContext)) {
        ReactNativeCmpModule(reactContext)
      } else {
        ReactNativeCmpLegacyModule(reactContext)
      }
    } else {
      null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      val moduleInfos: MutableMap<String, ReactModuleInfo> = HashMap()
      // For new architecture (TurboModule)
      moduleInfos[ReactNativeCmpModule.NAME] = ReactModuleInfo(
        ReactNativeCmpModule.NAME,
        ReactNativeCmpModule.NAME,
        false,  // canOverrideExistingModule
        false,  // needsEagerInit
        false,  // isCxxModule
        true // isTurboModule
      )
      // For legacy architecture
      moduleInfos[ReactNativeCmpLegacyModule.NAME] = ReactModuleInfo(
        ReactNativeCmpLegacyModule.NAME,
        ReactNativeCmpLegacyModule.NAME,
        false,  // canOverrideExistingModule
        false,  // needsEagerInit
        false,  // isCxxModule
        false // isTurboModule
      )
      moduleInfos
    }
  }
}
