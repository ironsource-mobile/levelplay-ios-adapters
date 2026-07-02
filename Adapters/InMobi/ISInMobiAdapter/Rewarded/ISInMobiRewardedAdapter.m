//
//  ISInMobiRewardedAdapter.m
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <InMobiSDK/InMobiSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISInMobiRewardedAdapter.h"
#import "ISInMobiRewardedDelegate.h"
#import "ISInMobiAdapter+Internal.h"
#import "ISInMobiAdapter.h"
#import "ISInMobiConstants.h"

@interface ISInMobiRewardedAdapter ()

@property (nonatomic, strong) IMInterstitial *rewardedAd;
@property (nonatomic, strong) ISInMobiRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISInMobiRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    // Validate placementId
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

    // Validate serverData
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
        self.rewardedAdDelegate = [[ISInMobiRewardedDelegate alloc] initWithDelegate:delegate];

        self.rewardedAd = [[IMInterstitial alloc] initWithPlacementId:[placementId longLongValue]
                                                             delegate:self.rewardedAdDelegate];

        // Load ad with bidding response
        NSData *data = [adData.serverData dataUsingEncoding:NSUTF8StringEncoding];
        [self.rewardedAd load:data];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:logAdNotReady, @"Rewarded"]}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd showFrom:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && [self.rewardedAd isReady];
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISInMobiAdapter *adapter = (ISInMobiAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
