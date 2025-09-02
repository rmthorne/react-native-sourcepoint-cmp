#ifdef RCT_NEW_ARCH_ENABLED
#import <ReactNativeCmpSpec/ReactNativeCmpSpec.h>
#import <React/RCTEventEmitter.h>
@interface ReactNativeCmp : NativeReactNativeCmpSpecBase <NativeReactNativeCmpSpec, ReactNativeCmpImplDelegate>
@end
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
@interface ReactNativeCmp : RCTEventEmitter <RCTBridgeModule>
@end
#endif

#if __has_include(<ReactNativeCmp/ReactNativeCmp-Swift.h>)
  #import <ReactNativeCmp/ReactNativeCmp-Swift.h>
#else
  #import "ReactNativeCmp-Swift.h"
#endif
