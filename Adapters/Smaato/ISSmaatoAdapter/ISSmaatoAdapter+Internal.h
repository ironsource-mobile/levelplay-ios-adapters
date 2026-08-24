//
//  ISSmaatoAdapter+Internal.h
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISSmaatoAdapter.h"
#import "ISSmaatoConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBiddingDataProtocol.h>
#import <SmaatoSDKCore/SmaatoSDKCore.h>
#import <SmaatoSDKBanner/SmaatoSDKBanner.h>
#import <SmaatoSDKInterstitial/SmaatoSDKInterstitial.h>
#import <SmaatoSDKRewardedAds/SmaatoSDKRewardedAds.h>
#import <SmaatoSDKInAppBidding/SMAInAppBidding.h>
#import <SmaatoSDKInAppBidding/SMAInAppBid.h>

@interface ISSmaatoAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (SMAAdRequestParams *)getAdRequestWithServerData:(NSString *)serverData;

@end
