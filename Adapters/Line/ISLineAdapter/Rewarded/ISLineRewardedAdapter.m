//
//  ISLineRewardedAdapter.m
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISLineRewardedAdapter.h"
#import "ISLineRewardedDelegate.h"
#import "ISLineAdapter+Internal.h"

@interface ISLineRewardedAdapter ()

@property (nonatomic, strong) FADVideoReward *rewardedAd;
@property (nonatomic, strong) FADAdLoader *rewardedAdLoader;
@property (nonatomic, strong) ISLineRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISLineRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *appId = [adData getString:appIdKey];
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logAppIdAndSlotId, appId, slotId);

    self.adAvailability = NO;

    ISLineAdapter *adapter = (ISLineAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    self.rewardedAdDelegate = [[ISLineRewardedDelegate alloc] initWithDelegate:delegate];
    self.rewardedAdLoader = [adapter getAdLoader:appId];

    if (self.rewardedAdLoader == nil) {
        LogAdapterApi_Internal(logError, logAdLoaderNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:logAdLoaderNil];
        return;
    }

    FADBidData *bidData = [[FADBidData alloc] initWithBidResponse:adData.serverData
                                                    withWatermark:nil];

    __weak ISLineRewardedAdapter *weakSelf = self;
    [self.rewardedAdLoader loadRewardAdWithBidData:bidData
                                  withLoadCallback:^(FADVideoReward *_Nullable ad, NSError *_Nullable error) {
        __typeof__(self) strongSelf = weakSelf;

        if (error) {
            LogAdapterDelegate_Internal(logError, error.localizedDescription);
            ISAdapterErrorType errorType = (error.code == lineNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        if (!ad) {
            LogAdapterDelegate_Internal(logError, logNoAd);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                         errorCode:ERROR_CODE_GENERIC
                                      errorMessage:logNoAd];
            return;
        }

        strongSelf.rewardedAd = ad;
        [strongSelf.rewardedAd setEventListener:strongSelf.rewardedAdDelegate];
        strongSelf.adAvailability = YES;
        [delegate adDidLoad];
    }];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        self.adAvailability = NO;
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    [self.rewardedAd showWithViewController:viewController];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.adAvailability;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    [self.rewardedAd setEventListener:nil];
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
    self.rewardedAdLoader = nil;
    self.adAvailability = NO;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISLineAdapter *adapter = (ISLineAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate
                                      appId:[adData getString:appIdKey]
                                     slotId:[adData getString:slotIdKey]];
}

@end
