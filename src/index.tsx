import type {
  Spec,
  SPCampaigns,
  SPUserData,
  LoadMessageParams,
  SPAction,
  SPBuildOptions,
  GDPRConsent,
  SPCampaignType,
  SPError,
} from './NativeReactNativeCmp';
import ReactNativeCmp, { SPMessageLanguage } from './NativeReactNativeCmp';
import type { EventEmitter } from 'react-native/Libraries/Types/CodegenTypes';
import { NativeEventEmitter, NativeModules } from 'react-native';

export * from './NativeReactNativeCmp';

const defaultBuildOptions: SPBuildOptions = {
  language: SPMessageLanguage.ENGLISH,
  messageTimeoutInSeconds: 30,
};

export default class SPConsentManager implements Spec {
  private eventEmitter: NativeEventEmitter | null = null;

  /** intended to be used by the SDK only */
  internalOnAction: EventEmitter<string>;
  /** intended to be used by the SDK only */
  internalOnError: EventEmitter<string>;

  onSPUIReady: EventEmitter<void>;
  onSPUIFinished: EventEmitter<void>;
  onFinished: EventEmitter<void>;
  onMessageInactivityTimeout: EventEmitter<void>;

  constructor() {
    if (ReactNativeCmp) {
      // For TurboModules, use the event emitters directly
      if (ReactNativeCmp.internalOnAction) {
        this.internalOnAction = ReactNativeCmp.internalOnAction;
        this.internalOnError = ReactNativeCmp.internalOnError;
        this.onSPUIReady = ReactNativeCmp.onSPUIReady;
        this.onSPUIFinished = ReactNativeCmp.onSPUIFinished;
        this.onFinished = ReactNativeCmp.onFinished;
        this.onMessageInactivityTimeout =
          ReactNativeCmp.onMessageInactivityTimeout;
      } else {
        // For legacy bridge modules, create NativeEventEmitter
        this.eventEmitter = new NativeEventEmitter(
          NativeModules.ReactNativeCmp
        );
        this.internalOnAction = this.eventEmitter.addListener.bind(
          this.eventEmitter,
          'internalOnAction'
        ) as any;
        this.internalOnError = this.eventEmitter.addListener.bind(
          this.eventEmitter,
          'internalOnError'
        ) as any;
        this.onSPUIReady = this.eventEmitter.addListener.bind(
          this.eventEmitter,
          'onSPUIReady'
        ) as any;
        this.onSPUIFinished = this.eventEmitter.addListener.bind(
          this.eventEmitter,
          'onSPUIFinished'
        ) as any;
        this.onFinished = this.eventEmitter.addListener.bind(
          this.eventEmitter,
          'onFinished'
        ) as any;
        this.onMessageInactivityTimeout = this.eventEmitter.addListener.bind(
          this.eventEmitter,
          'onMessageInactivityTimeout'
        ) as any;
      }
    } else {
      // Fallback empty event emitters
      const emptyEmitter = () => ({ remove: () => {} });
      this.internalOnAction = emptyEmitter as any;
      this.internalOnError = emptyEmitter as any;
      this.onSPUIReady = emptyEmitter as any;
      this.onSPUIFinished = emptyEmitter as any;
      this.onFinished = emptyEmitter as any;
      this.onMessageInactivityTimeout = emptyEmitter as any;
    }
  }

  onAction(handler: (action: SPAction) => void) {
    if (ReactNativeCmp?.internalOnAction) {
      // TurboModule architecture
      ReactNativeCmp.internalOnAction((stringifiedAction) => {
        handler(JSON.parse(stringifiedAction) as SPAction);
      });
    } else if (this.eventEmitter) {
      // Legacy bridge architecture
      this.eventEmitter.addListener('internalOnAction', (stringifiedAction) => {
        handler(JSON.parse(stringifiedAction) as SPAction);
      });
    }
  }

  onError(handler: (error: SPError) => void) {
    if (ReactNativeCmp?.internalOnError) {
      // TurboModule architecture
      ReactNativeCmp.internalOnError((stringifiedError) => {
        handler(JSON.parse(stringifiedError) as SPError);
      });
    } else if (this.eventEmitter) {
      // Legacy bridge architecture
      this.eventEmitter.addListener('internalOnError', (stringifiedError) => {
        handler(JSON.parse(stringifiedError) as SPError);
      });
    }
  }

  getConstants?(): {} {
    throw new Error('Method not implemented.');
  }

  build(
    accountId: number,
    propertyId: number,
    propertyName: string,
    campaigns: SPCampaigns,
    options: SPBuildOptions = defaultBuildOptions
  ) {
    if (ReactNativeCmp?.build) {
      ReactNativeCmp.build(
        accountId,
        propertyId,
        propertyName,
        campaigns,
        options
      );
    }
  }

  getUserData(): Promise<SPUserData> {
    if (ReactNativeCmp?.getUserData) {
      return ReactNativeCmp.getUserData();
    }
    return Promise.reject(new Error('Native module not available'));
  }

  loadMessage(params?: LoadMessageParams) {
    if (ReactNativeCmp?.loadMessage) {
      ReactNativeCmp.loadMessage(params);
    }
  }

  clearLocalData() {
    if (ReactNativeCmp?.clearLocalData) {
      ReactNativeCmp.clearLocalData();
    }
  }

  loadGDPRPrivacyManager(pmId: string) {
    if (ReactNativeCmp?.loadGDPRPrivacyManager) {
      ReactNativeCmp.loadGDPRPrivacyManager(pmId);
    }
  }

  loadUSNatPrivacyManager(pmId: string) {
    if (ReactNativeCmp?.loadUSNatPrivacyManager) {
      ReactNativeCmp.loadUSNatPrivacyManager(pmId);
    }
  }

  loadGlobalCmpPrivacyManager(pmId: string) {
    if (ReactNativeCmp?.loadGlobalCmpPrivacyManager) {
      ReactNativeCmp.loadGlobalCmpPrivacyManager(pmId);
    }
  }

  loadPreferenceCenter(id: string) {
    if (ReactNativeCmp?.loadPreferenceCenter) {
      ReactNativeCmp.loadPreferenceCenter(id);
    }
  }

  dismissMessage(): void {
    if (ReactNativeCmp?.dismissMessage) {
      ReactNativeCmp.dismissMessage();
    }
  }

  postCustomConsentGDPR(
    vendors: string[],
    categories: string[],
    legIntCategories: string[],
    callback: (consent: GDPRConsent) => void
  ) {
    if (ReactNativeCmp?.postCustomConsentGDPR) {
      ReactNativeCmp.postCustomConsentGDPR(
        vendors,
        categories,
        legIntCategories,
        callback
      );
    }
  }

  postDeleteCustomConsentGDPR(
    vendors: string[],
    categories: string[],
    legIntCategories: string[],
    callback: (consent: GDPRConsent) => void
  ) {
    if (ReactNativeCmp?.postDeleteCustomConsentGDPR) {
      ReactNativeCmp.postDeleteCustomConsentGDPR(
        vendors,
        categories,
        legIntCategories,
        callback
      );
    }
  }

  rejectAll(campaignType: SPCampaignType) {
    if (ReactNativeCmp?.rejectAll) {
      ReactNativeCmp.rejectAll(campaignType);
    }
  }
}
