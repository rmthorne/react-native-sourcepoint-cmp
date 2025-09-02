#import "ReactNativeCmpLegacy.h"
#import <React/RCTLog.h>

#if __has_include(<ReactNativeCmp/ReactNativeCmp-Swift.h>)
  #import <ReactNativeCmp/ReactNativeCmp-Swift.h>
#else
  #import "ReactNativeCmp-Swift.h"
#endif

@interface ReactNativeCmpLegacy () <SPDelegate>
@property (nonatomic, strong) ReactNativeCmpImpl *sdk;
@end

@implementation ReactNativeCmpLegacy {
  bool hasListeners;
}

RCT_EXPORT_MODULE(ReactNativeCmp)

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[
    @"internalOnAction",
    @"onSPUIReady", 
    @"onSPUIFinished",
    @"onFinished",
    @"onMessageInactivityTimeout",
    @"internalOnError"
  ];
}

- (void)startObserving {
  hasListeners = YES;
}

- (void)stopObserving {
  hasListeners = NO;
}

- (void)sendEventWithName:(NSString *)eventName body:(id)body {
  if (hasListeners) {
    [super sendEventWithName:eventName body:body];
  }
}

RCT_EXPORT_METHOD(build:(double)accountId
                  propertyId:(double)propertyId
                  propertyName:(NSString *)propertyName
                  campaigns:(NSDictionary *)campaigns
                  options:(NSDictionary *)options) {
  
  if (self.sdk == nil) {
    self.sdk = [[ReactNativeCmpImpl alloc] init];
  }

  // Convert campaigns dictionary to native format
  RNSPCampaign *gdpr = nil;
  RNSPCampaign *usnat = nil;
  RNSPCampaign *preferences = nil;
  RNSPCampaign *globalcmp = nil;

  if (campaigns[@"gdpr"]) {
    NSDictionary *gdprCampaign = campaigns[@"gdpr"];
    NSDictionary *targetingParams = gdprCampaign[@"targetingParams"] ?: @{};
    NSString *groupPmId = gdprCampaign[@"groupPmId"];
    
    gdpr = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams
                                               groupPmId:groupPmId
                                  supportLegacyUSPString:false];
  }

  if (campaigns[@"usnat"]) {
    NSDictionary *usnatCampaign = campaigns[@"usnat"];
    NSDictionary *targetingParams = usnatCampaign[@"targetingParams"] ?: @{};
    NSString *groupPmId = usnatCampaign[@"groupPmId"];
    BOOL legacy = [usnatCampaign[@"supportLegacyUSPString"] boolValue];
    
    usnat = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams
                                                groupPmId:groupPmId
                                   supportLegacyUSPString:legacy];
  }

  if (campaigns[@"preferences"]) {
    NSDictionary *preferencesCampaign = campaigns[@"preferences"];
    NSDictionary *targetingParams = preferencesCampaign[@"targetingParams"] ?: @{};
    NSString *groupPmId = preferencesCampaign[@"groupPmId"];
    
    preferences = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams
                                                      groupPmId:groupPmId
                                         supportLegacyUSPString:false];
  }

  if (campaigns[@"globalcmp"]) {
    NSDictionary *globalCMPCampaign = campaigns[@"globalcmp"];
    NSDictionary *targetingParams = globalCMPCampaign[@"targetingParams"] ?: @{};
    NSString *groupPmId = globalCMPCampaign[@"groupPmId"];
    
    globalcmp = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams
                                                      groupPmId:groupPmId
                                         supportLegacyUSPString:false];
  }

  RNSPCampaigns *internalCampaigns = [[RNSPCampaigns alloc] initWithGdpr:gdpr
                                                                    ccpa:nil
                                                                   usnat:usnat
                                                                   ios14:nil
                                                             preferences:preferences
                                                               globalcmp:globalcmp
                                                             environment:RNSPCampaignEnvPublic];

  // Convert options dictionary to native format
  NSString *language = options[@"language"] ?: @"en";
  NSInteger messageTimeout = [options[@"messageTimeoutInSeconds"] integerValue] ?: 30;
  
  RNBuildOptions *buildOptions = [[RNBuildOptions alloc] initWithLanguage:language
                                                            messageTimeout:messageTimeout];

  [self.sdk buildWithAccountId:(NSInteger)accountId
                    propertyId:(NSInteger)propertyId
                  propertyName:propertyName
                     campaigns:internalCampaigns
                       options:buildOptions
                      delegate:self];
}

RCT_EXPORT_METHOD(loadMessage:(NSDictionary *)params) {
  NSString *authId = params[@"authId"];
  RNSPLoadMessageParams *loadParams = [[RNSPLoadMessageParams alloc] initWithAuthId:authId];
  [self.sdk loadMessage:loadParams];
}

RCT_EXPORT_METHOD(clearLocalData) {
  [self.sdk clearLocalData];
}

RCT_EXPORT_METHOD(getUserData:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [self.sdk getUserData:resolve reject:reject];
}

RCT_EXPORT_METHOD(loadGDPRPrivacyManager:(NSString *)pmId) {
  [self.sdk loadGDPRPrivacyManager:pmId];
}

RCT_EXPORT_METHOD(loadUSNatPrivacyManager:(NSString *)pmId) {
  [self.sdk loadUSNatPrivacyManager:pmId];
}

RCT_EXPORT_METHOD(loadGlobalCmpPrivacyManager:(NSString *)pmId) {
  [self.sdk loadGlobalCMPPrivacyManager:pmId];
}

RCT_EXPORT_METHOD(loadPreferenceCenter:(NSString *)id) {
  [self.sdk loadPreferenceCenter:id];
}

RCT_EXPORT_METHOD(dismissMessage) {
  [self.sdk dismissMessage];
}

RCT_EXPORT_METHOD(postCustomConsentGDPR:(NSArray *)vendors
                  categories:(NSArray *)categories
                  legIntCategories:(NSArray *)legIntCategories
                  callback:(RCTResponseSenderBlock)callback) {
  [self.sdk postCustomConsentGDPR:vendors :categories :legIntCategories :callback];
}

RCT_EXPORT_METHOD(postDeleteCustomConsentGDPR:(NSArray *)vendors
                  categories:(NSArray *)categories
                  legIntCategories:(NSArray *)legIntCategories
                  callback:(RCTResponseSenderBlock)callback) {
  [self.sdk postDeleteCustomConsentGDPR:vendors :categories :legIntCategories :callback];
}

RCT_EXPORT_METHOD(rejectAll:(NSString *)campaignType) {
  [self.sdk rejectAll:campaignType];
}

// MARK: SPDelegate
- (void)onAction:(RNAction *)action {
  [self sendEventWithName:@"internalOnAction" body:[action stringifiedJson]];
}

- (void)onErrorWithDescription:(NSString *)description {
  NSDictionary *dict = @{@"description": description};
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
  NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  [self sendEventWithName:@"internalOnError" body:json];
}

- (void)onFinished {
  [self sendEventWithName:@"onFinished" body:nil];
}

- (void)onMessageInactivityTimeout {
  [self sendEventWithName:@"onMessageInactivityTimeout" body:nil];
}

- (void)onSPUIFinished {
  [self sendEventWithName:@"onSPUIFinished" body:nil];
}

- (void)onSPUIReady {
  [self sendEventWithName:@"onSPUIReady" body:nil];
}

@end