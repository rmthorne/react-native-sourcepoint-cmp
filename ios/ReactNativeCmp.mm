#import "ReactNativeCmp.h"

#if __has_include(<ReactNativeCmp/ReactNativeCmp-Swift.h>)
  #import <ReactNativeCmp/ReactNativeCmp-Swift.h>
#else
  #import "ReactNativeCmp-Swift.h"
#endif

@implementation ReactNativeCmp {
  ReactNativeCmpImpl *sdk;
  bool hasListeners;
}

#ifdef RCT_NEW_ARCH_ENABLED
// TurboModule implementation for new architecture
RCT_EXPORT_MODULE(ReactNativeCmpImpl)

- (void)build:(double)accountId propertyId:(double)propertyId propertyName:(nonnull NSString *)propertyName campaigns:(JS::NativeReactNativeCmp::SPCampaigns &)campaigns options:(JS::NativeReactNativeCmp::SPBuildOptions &)options {
  if (sdk == nil) {
    sdk = [[ReactNativeCmpImpl alloc] init];
  }

  RNSPCampaign *gdpr = nil;
  RNSPCampaign *usnat = nil;
  RNSPCampaign *preferences = nil;
  RNSPCampaign *globalcmp = nil;

  if (campaigns.gdpr().has_value()) {
    auto gdprCampaign = campaigns.gdpr().value();
    NSDictionary *targetingParams = (NSDictionary *)gdprCampaign.targetingParams();

    gdpr = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams ?: @{}
                                               groupPmId:gdprCampaign.groupPmId()
                                  supportLegacyUSPString:false];
  }

  if (campaigns.usnat().has_value()) {
    auto usnatCampaign = campaigns.usnat().value();
    NSDictionary *targetingParams = (NSDictionary *)usnatCampaign.targetingParams();
    BOOL legacy = usnatCampaign.supportLegacyUSPString().value_or(false);

    usnat = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams ?: @{}
                                                groupPmId:usnatCampaign.groupPmId()
                                   supportLegacyUSPString:legacy];
  }

  if (campaigns.preferences().has_value()) {
    auto preferencesCampaign = campaigns.preferences().value();
    NSDictionary *targetingParams = (NSDictionary *)preferencesCampaign.targetingParams();

    preferences = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams ?: @{}
                                                      groupPmId:preferencesCampaign.groupPmId()
                                         supportLegacyUSPString:false];
  }

  if (campaigns.globalcmp().has_value()) {
    auto globalCMPCampaign = campaigns.globalcmp().value();
    NSDictionary *targetingParams = (NSDictionary *)globalCMPCampaign.targetingParams();

    globalcmp = [[RNSPCampaign alloc] initWithTargetingParams:targetingParams ?: @{}
                                                      groupPmId:globalCMPCampaign.groupPmId()
                                         supportLegacyUSPString:false];
  }

  RNSPCampaigns *internalCampaigns = [[RNSPCampaigns alloc] initWithGdpr: gdpr
                                                                    ccpa:nil
                                                                   usnat:usnat
                                                                   ios14:nil
                                                             preferences:preferences
                                                             globalcmp: globalcmp
                                                             environment:RNSPCampaignEnvPublic];

  RNBuildOptions *buildOptions = [
    [RNBuildOptions alloc]
      initWithLanguage: options.language()
      messageTimeout: options.messageTimeoutInSeconds().has_value() ? (NSInteger)options.messageTimeoutInSeconds().value(): 30
  ];

  [sdk
   buildWithAccountId:(NSInteger)accountId
   propertyId:(NSInteger)propertyId
   propertyName:propertyName
   campaigns: internalCampaigns
   options: buildOptions
   delegate: self
  ];
}

- (void)loadMessage:(JS::NativeReactNativeCmp::LoadMessageParams &)params {
  [sdk loadMessage: [[RNSPLoadMessageParams alloc] initWithAuthId:params.authId()]];
}

- (void)clearLocalData {
  [sdk clearLocalData];
}

- (void)getUserData:(nonnull RCTPromiseResolveBlock)resolve reject:(nonnull RCTPromiseRejectBlock)reject {
  [sdk getUserData:resolve reject:reject];
}

- (void)loadGDPRPrivacyManager:(nonnull NSString *)pmId {
  [sdk loadGDPRPrivacyManager: pmId];
}

- (void)loadUSNatPrivacyManager:(nonnull NSString *)pmId {
  [sdk loadUSNatPrivacyManager: pmId];
}

- (void)loadGlobalCmpPrivacyManager:(nonnull NSString *)pmId { 
  [sdk loadGlobalCMPPrivacyManager: pmId];
}

- (void)loadPreferenceCenter:(nonnull NSString *)id { 
  [sdk loadPreferenceCenter: id];
}

- (void)dismissMessage { 
  [sdk dismissMessage];
}

- (void)postCustomConsentGDPR:(NSArray *)vendors
               categories:(NSArray *)categories
         legIntCategories:(NSArray *)legIntCategories
                 callback:(RCTResponseSenderBlock)callback {
  [sdk postCustomConsentGDPR:vendors :categories :legIntCategories :callback];
}

- (void)postDeleteCustomConsentGDPR:(NSArray *)vendors
                     categories:(NSArray *)categories
               legIntCategories:(NSArray *)legIntCategories
                       callback:(RCTResponseSenderBlock)callback{
  [sdk postDeleteCustomConsentGDPR:vendors :categories :legIntCategories :callback];
}

- (void)rejectAll:(nonnull NSString *)campaignType {
  [sdk rejectAll:campaignType];
}

// MARK: SPDelegate
- (void)onAction:(RNAction*)action {
  [self emitInternalOnAction: [action stringifiedJson]];
}

- (void)onErrorWithDescription:(NSString * _Nonnull)description {
  NSDictionary *dict = @{@"description": description};
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
  NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  [self emitInternalOnError: json];
}

- (void)onFinished {
  [self emitOnFinished];
}

- (void)onMessageInactivityTimeout {
  [self emitOnMessageInactivityTimeout];
}

- (void)onSPUIFinished {
  [self emitOnSPUIFinished];
}

- (void)onSPUIReady {
  [self emitOnSPUIReady];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeReactNativeCmpSpecJSI>(params);
}

#else
// Legacy bridge module implementation
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
  
  if (sdk == nil) {
    sdk = [[ReactNativeCmpImpl alloc] init];
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

  [sdk buildWithAccountId:(NSInteger)accountId
               propertyId:(NSInteger)propertyId
             propertyName:propertyName
                campaigns:internalCampaigns
                  options:buildOptions
                 delegate:self];
}

RCT_EXPORT_METHOD(loadMessage:(NSDictionary *)params) {
  NSString *authId = params[@"authId"];
  RNSPLoadMessageParams *loadParams = [[RNSPLoadMessageParams alloc] initWithAuthId:authId];
  [sdk loadMessage:loadParams];
}

RCT_EXPORT_METHOD(clearLocalData) {
  [sdk clearLocalData];
}

RCT_EXPORT_METHOD(getUserData:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [sdk getUserData:resolve reject:reject];
}

RCT_EXPORT_METHOD(loadGDPRPrivacyManager:(NSString *)pmId) {
  [sdk loadGDPRPrivacyManager:pmId];
}

RCT_EXPORT_METHOD(loadUSNatPrivacyManager:(NSString *)pmId) {
  [sdk loadUSNatPrivacyManager:pmId];
}

RCT_EXPORT_METHOD(loadGlobalCmpPrivacyManager:(NSString *)pmId) {
  [sdk loadGlobalCMPPrivacyManager:pmId];
}

RCT_EXPORT_METHOD(loadPreferenceCenter:(NSString *)id) {
  [sdk loadPreferenceCenter:id];
}

RCT_EXPORT_METHOD(dismissMessage) {
  [sdk dismissMessage];
}

RCT_EXPORT_METHOD(postCustomConsentGDPR:(NSArray *)vendors
                  categories:(NSArray *)categories
                  legIntCategories:(NSArray *)legIntCategories
                  callback:(RCTResponseSenderBlock)callback) {
  [sdk postCustomConsentGDPR:vendors :categories :legIntCategories :callback];
}

RCT_EXPORT_METHOD(postDeleteCustomConsentGDPR:(NSArray *)vendors
                  categories:(NSArray *)categories
                  legIntCategories:(NSArray *)legIntCategories
                  callback:(RCTResponseSenderBlock)callback) {
  [sdk postDeleteCustomConsentGDPR:vendors :categories :legIntCategories :callback];
}

RCT_EXPORT_METHOD(rejectAll:(NSString *)campaignType) {
  [sdk rejectAll:campaignType];
}

// MARK: SPDelegate (Legacy implementation)
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

#endif

@end
