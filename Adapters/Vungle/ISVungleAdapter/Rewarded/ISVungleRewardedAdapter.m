//
//  ISVungleRewardedAdapter.m
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <VungleAdsSDK/VungleAdsSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISVungleRewardedAdapter.h"
#import "ISVungleRewardedDelegate.h"
#import "ISVungleAdapter+Internal.h"
#import "ISVungleAdapter.h"
#import "ISVungleConstants.h"

@interface ISVungleRewardedAdapter ()

@property (nonatomic, strong) VungleRewarded *rewardedAd;
@property (nonatomic, strong) ISVungleRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISVungleRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    self.rewardedAdDelegate = [[ISVungleRewardedDelegate alloc] initWithDelegate:delegate];

    self.rewardedAd = [[VungleRewarded alloc] initWithPlacementId:placementId];
    self.rewardedAd.delegate = self.rewardedAdDelegate;
    self.rewardedAd.adapterAdFormat = adapterFormatRewarded;

    [self.rewardedAd load:adData.serverData];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:logShowFailed}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    NSString *userId = [self dynamicUserId];
    if (userId.length) {
        LogAdapterApi_Internal(logSetUserId, userId);
        [self.rewardedAd setUserIdWithUserId:userId];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd presentWith:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && [self.rewardedAd canPlayAd];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISVungleAdapter *adapter = (ISVungleAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
