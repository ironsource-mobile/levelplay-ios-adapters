//
//  ISFacebookRewardedAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISFacebookRewardedAdapter.h"
#import "ISFacebookRewardedDelegate.h"
#import "ISFacebookAdapter+Internal.h"
#import "ISFacebookAdapter.h"
#import "ISFacebookConstants.h"

@interface ISFacebookRewardedAdapter ()

@property (nonatomic, strong) FBRewardedVideoAd            *rewardedAd;
@property (nonatomic, strong) ISFacebookRewardedDelegate   *rewardedAdDelegate;

@end

@implementation ISFacebookRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    if (!adData.serverData) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, serverDataKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAdDelegate = [[ISFacebookRewardedDelegate alloc] initWithDelegate:delegate];

        self.rewardedAd = [[FBRewardedVideoAd alloc] initWithPlacementID:placementId];
        self.rewardedAd.delegate = self.rewardedAdDelegate;

        [self.rewardedAd loadAdWithBidPayload:adData.serverData];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSString *errorMessage = [NSString stringWithFormat:errorShowFailed, networkName];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // set dynamic user id to ad if exists
        NSString *userId = [self dynamicUserId];
        if (userId.length) {
            [self.rewardedAd setRewardDataWithUserID:userId
                                        withCurrency:@""];
        }

        if (![self.rewardedAd showAdFromRootViewController:viewController]) {
            NSString *errorMessage = [NSString stringWithFormat:errorShowFailed, networkName];
            NSError *error = [NSError errorWithDomain:networkName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
            LogAdapterApi_Internal(logError, error);
            [delegate adDidFailToShowWithErrorCode:error.code
                                      errorMessage:error.localizedDescription];
        }
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.rewardedAd.isAdValid;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Bidding Data

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISFacebookAdapter *adapter = (ISFacebookAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
