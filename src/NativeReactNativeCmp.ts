import { TurboModuleRegistry, NativeModules } from 'react-native';
import type { TurboModule } from 'react-native';
import type { EventEmitter } from 'react-native/Libraries/Types/CodegenTypes';

export type SPCampaign = {
  groupPmId?: string;
  targetingParams?: { [key: string]: string };
  supportLegacyUSPString?: boolean;
};

export const enum SPCampaignEnvironment {
  Public = 'Public',
  Stage = 'Stage',
}

export const enum SPCampaignType {
  Gdpr = 'gdpr',
  UsNat = 'usnat',
  IOS14 = 'ios14',
  Preferences = 'preferences',
  GlobalCmp = 'globalcmp',
}

export const enum SPMessageLanguage {
  ALBANIAN = 'sq',
  ARABIC = 'ar',
  BASQUE = 'eu',
  BOSNIAN_LATIN = 'bs',
  BULGARIAN = 'bg',
  CATALAN = 'ca',
  CHINESE_SIMPLIFIED = 'zh',
  CHINESE_TRADITIONAL = 'zh-hant',
  CROATIAN = 'hr',
  CZECH = 'cs',
  DANISH = 'da',
  DUTCH = 'nl',
  ENGLISH = 'en',
  ESTONIAN = 'et',
  FINNISH = 'fi',
  FRENCH = 'fr',
  GALICIAN = 'gl',
  GEORGIAN = 'ka',
  GERMAN = 'de',
  GREEK = 'el',
  HEBREW = 'he',
  HINDI = 'hi',
  HUNGARIAN = 'hu',
  INDONESIAN = 'id',
  ITALIAN = 'it',
  JAPANESE = 'ja',
  KOREAN = 'ko',
  LATVIAN = 'lv',
  LITHUANIAN = 'lt',
  MACEDONIAN = 'mk',
  MALAY = 'ms',
  MALTESE = 'mt',
  NORWEGIAN = 'no',
  POLISH = 'pl',
  PORTUGUESE_BRAZIL = 'pt-br',
  PORTUGUESE_PORTUGAL = 'pt-pt',
  ROMANIAN = 'ro',
  RUSSIAN = 'ru',
  SERBIAN_CYRILLIC = 'sr-cyrl',
  SERBIAN_LATIN = 'sr-latn',
  SLOVAK = 'sk',
  SLOVENIAN = 'sl',
  SPANISH = 'es',
  SWAHILI = 'sw',
  SWEDISH = 'sv',
  TAGALOG = 'tl',
  THAI = 'th',
  TURKISH = 'tr',
  UKRAINIAN = 'uk',
  VIETNAMESE = 'vi',
  WELSH = 'cy',
}

export const enum SPActionType {
  acceptAll = 'acceptAll',
  rejectAll = 'rejectAll',
  saveAndExit = 'saveAndExit',
  showOptions = 'showOptions',
  dismiss = 'dismiss',
  pmCancel = 'pmCancel',
  unknown = 'unknown',
}

export type SPCampaigns = {
  gdpr?: SPCampaign;
  usnat?: SPCampaign;
  preferences?: SPCampaign;
  globalcmp?: SPCampaign;
  environment?: SPCampaignEnvironment;
};

export type GDPRConsentStatus = {
  consentedAll?: boolean;
  consentedAny?: boolean;
  rejectedAny?: boolean;
};

export type USNatConsentStatus = {
  consentedAll?: boolean;
  consentedAny?: boolean;
  rejectedAny?: boolean;
  sellStatus?: boolean;
  shareStatus?: boolean;
  sensitiveDataStatus?: boolean;
  gpcStatus?: boolean;
};

export type GDPRVendorGrant = {
  granted: boolean;
  purposes: { [key: string]: boolean };
};

export type GDPRConsent = {
  applies: boolean;
  uuid?: string;
  expirationDate?: string;
  createdDate?: string;
  euconsent?: string;
  vendorGrants: { [key: string]: GDPRVendorGrant };
  statuses?: GDPRConsentStatus;
  tcfData?: { [key: string]: string };
};

export type Consentable = {
  consented: boolean;
  id: string;
};

export type ConsentSection = {
  id: number;
  name: string;
  consentString: string;
};

export type USNatConsent = {
  applies: boolean;
  uuid?: string;
  expirationDate?: string;
  createdDate?: string;
  consentSections: Array<ConsentSection>;
  statuses?: USNatConsentStatus;
  vendors: Array<Consentable>;
  categories: Array<Consentable>;
  gppData?: { [key: string]: string };
};

export type GlobalCMPConsent = {
  applies: boolean;
  uuid?: string;
  expirationDate?: string;
  createdDate?: string;
  vendors: Array<Consentable>;
  categories: Array<Consentable>;
};

export type SPUserData = {
  gdpr?: GDPRConsent;
  usnat?: USNatConsent;
  preferences?: PreferencesConsent;
  globalcmp?: GlobalCMPConsent;
};

export type LoadMessageParams = {
  authId?: string;
};

export type SPAction = {
  actionType: SPActionType;
  customActionId?: string;
};

export const enum PreferencesSubType {
  AIPolicy = 'AIPolicy',
  TermsAndConditions = 'TermsAndConditions',
  PrivacyPolicy = 'PrivacyPolicy',
  LegalPolicy = 'LegalPolicy',
  TermsOfSale = 'TermsOfSale',
  Unknown = 'Unknown',
}

export type PreferencesChannel = {
  id: number;
  status: boolean;
};

export type PreferencesStatus = {
  categoryId: number;
  channels: PreferencesChannel[];
  changed?: boolean;
  dateConsented?: string;
  subType?: PreferencesSubType;
  versionId?: string;
};

export type PreferencesConsent = {
  dateCreated: string;
  uuid?: string;
  status: PreferencesStatus[];
  rejectedStatus: PreferencesStatus[];
};

export type SPBuildOptions = {
  language?: SPMessageLanguage;
  messageTimeoutInSeconds?: number;
  androidDismissMessageOnBackPress?: boolean;
};

export type SPError = {
  description: string;
};

export interface Spec extends TurboModule {
  build(
    accountId: number,
    propertyId: number,
    propertyName: string,
    campaigns: SPCampaigns,
    options?: SPBuildOptions
  ): void;
  getUserData(): Promise<SPUserData>;
  loadMessage(params?: LoadMessageParams): void;
  clearLocalData(): void;
  loadGDPRPrivacyManager(pmId: string): void;
  loadUSNatPrivacyManager(pmId: string): void;
  loadGlobalCmpPrivacyManager(pmId: string): void;
  loadPreferenceCenter(id: string): void;
  dismissMessage(): void;
  postCustomConsentGDPR(
    vendors: string[],
    categories: string[],
    legIntCategories: string[],
    callback: (consent: GDPRConsent) => void
  ): void;
  postDeleteCustomConsentGDPR(
    vendors: string[],
    categories: string[],
    legIntCategories: string[],
    callback: (consent: GDPRConsent) => void
  ): void;
  rejectAll(campaignType: SPCampaignType): void;

  readonly internalOnAction: EventEmitter<string>;
  readonly onSPUIReady: EventEmitter<void>;
  readonly onSPUIFinished: EventEmitter<void>;
  readonly onFinished: EventEmitter<void>;
  readonly onMessageInactivityTimeout: EventEmitter<void>;
  readonly internalOnError: EventEmitter<string>;
}

function createNativeReactNativeCmp(): Spec | null {
  if (TurboModuleRegistry.getEnforcing) {
    try {
      return TurboModuleRegistry.getEnforcing<Spec>('ReactNativeCmp');
    } catch (e) {
      // TurboModule not available, fallback to legacy
    }
  }

  // Fallback to legacy bridge
  return NativeModules.ReactNativeCmp as Spec;
}

export default createNativeReactNativeCmp();
