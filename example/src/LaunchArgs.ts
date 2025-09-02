import type {
  SPCampaigns,
  SPBuildOptions,
} from '@sourcepoint/react-native-cmp';

export type LaunchArgs = {
  config?: {
    accountId?: number;
    propertyId?: number;
    propertyName?: string;
    gdprPMId?: string;
    usnatPMId?: string;
    campaigns?: SPCampaigns;
    buildOptions?: SPBuildOptions;
  };
  authId?: string;
  clearData?: boolean;
};
