//
//  ISYandexRewardedAdapter.m
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

@import YandexMobileAds;
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISYandexRewardedAdapter.h"
#import "ISYandexRewardedDelegate.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"

@interface ISYandexRewardedAdapter ()

@property (nonatomic, strong) YMARewardedAd *rewardedAd;
@property (nonatomic, strong) YMARewardedAdLoader *rewardedAdLoader;
@property (nonatomic, strong) ISYandexRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISYandexRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    // validate adUnitId
    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.adAvailability = NO;

    // create delegate for showing ads
    self.rewardedAdDelegate = [[ISYandexRewardedDelegate alloc] initWithDelegate:delegate];

    // create adLoader
    self.rewardedAdLoader = [[YMARewardedAdLoader alloc] init];

    // get ad request parameters from adapter
    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }
    YMAAdRequest *adRequest = [adapter createAdRequestWithBidResponse:adData.serverData
                                                              adUnitId:adUnitId];

    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self) weakSelf = self;
        [self.rewardedAdLoader loadAdWith:adRequest completionHandler:^(YMARewardedAd * _Nullable rewardedAd, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }

            if (error) {
                LogAdapterDelegate_Internal(logCallbackFailed, adUnitId, error.localizedDescription);
                ISAdapterErrorType errorType = (error.code == yandexNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
                strongSelf.rewardedAd = nil;
                strongSelf.adAvailability = NO;
                [delegate adDidFailToLoadWithErrorType:errorType
                                             errorCode:error.code
                                          errorMessage:error.localizedDescription];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Store ad object first to retain it
                    strongSelf.rewardedAd = rewardedAd;
                    strongSelf.rewardedAd.delegate = strongSelf.rewardedAdDelegate;
                    strongSelf.adAvailability = YES;

                    // Extract creative IDs and pass as extra data if available
                    NSString *creativeId = [ISYandexAdapter buildCreativeIdStringFromCreatives:strongSelf.rewardedAd.adInfo.creatives];
                    LogAdapterDelegate_Internal(logCreativeId, creativeId);

                    if (creativeId.length) {
                        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
                        [delegate adDidLoadWithExtraData:extraData];
                    } else {
                        [delegate adDidLoad];
                    }
                });
            }
        }];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd showFromViewController:viewController];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd.delegate = nil;
        self.rewardedAd = nil;
        self.rewardedAdLoader = nil;
        self.rewardedAdDelegate = nil;
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.adAvailability;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    YMABidderTokenRequest *requestConfiguration = [YMABidderTokenRequest rewardedWithTargeting:nil
                                                                                    parameters:[adapter getConfigParams]];

    [adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                delegate:delegate];
}

@end
