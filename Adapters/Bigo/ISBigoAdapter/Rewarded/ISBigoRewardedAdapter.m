//
//  ISBigoRewardedAdapter.m
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BigoADS/BigoAdSdk.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISBigoRewardedAdapter.h"
#import "ISBigoRewardedDelegate.h"
#import "ISBigoAdapter+Internal.h"
#import "ISBigoAdapter.h"
#import "ISBigoConstants.h"

@interface ISBigoRewardedAdapter ()

@property (nonatomic, strong) BigoRewardVideoAd          *rewardedAd;
@property (nonatomic, strong) BigoRewardVideoAdLoader    *rewardedAdLoader;
@property (nonatomic, strong) ISBigoRewardedDelegate     *rewardedAdDelegate;

@end

@implementation ISBigoRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    if (!slotId || slotId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingSlotId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISBigoAdapter *adapter = (ISBigoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:logAdapterNil];
        return;
    }

    self.rewardedAdDelegate = [[ISBigoRewardedDelegate alloc] initWithAdapter:self
                                                                     delegate:delegate];

    BigoRewardVideoAdRequest *request = [[BigoRewardVideoAdRequest alloc] initWithSlotId:slotId];
    [request setServerBidPayload:adData.serverData];

    self.rewardedAdLoader = [[BigoRewardVideoAdLoader alloc] initWithRewardVideoAdLoaderDelegate:self.rewardedAdDelegate];
    self.rewardedAdLoader.ext = [adapter getMediationInfo];
    [self.rewardedAdLoader loadAd:request];
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

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd show:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && ![self.rewardedAd isExpired];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd destroy];
        self.rewardedAd = nil;
    });
    self.rewardedAdDelegate = nil;
    self.rewardedAdLoader = nil;
}

#pragma mark - Helper Methods

- (void)storeRewardedAd:(BigoRewardVideoAd *)ad {
    self.rewardedAd = ad;
    [self.rewardedAd setRewardVideoAdInteractionDelegate:self.rewardedAdDelegate];
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISBigoAdapter *adapter = (ISBigoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
