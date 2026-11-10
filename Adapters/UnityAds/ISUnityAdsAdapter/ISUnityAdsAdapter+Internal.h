//
//  ISUnityAdsAdapter+Internal.h
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISUnityAdsAdapter.h"
#import "ISUnityAdsConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBiddingDataProtocol.h>
#import <UnityAds/UnityAds.h>

@interface ISUnityAdsAdapter ()

- (UADSMediationInfo *)adapterMediationInfo;

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            adFormat:(UADSAdFormat)format
                            delegate:(id<ISBiddingDataDelegate>)delegate;

@end
