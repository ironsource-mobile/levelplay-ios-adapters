//
//  ISVoodooRewardedAdapter.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISVoodooRewardedAdapter.h"
#import "ISVoodooRewardedDelegate.h"
#import "ISVoodooAdapter+Internal.h"

@interface ISVoodooRewardedAdapter ()

@property (nonatomic, strong) AdnFullscreenAdController *rewardedAd;
@property (nonatomic, strong) ISVoodooRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISVoodooRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    self.rewardedAdDelegate = [[ISVoodooRewardedDelegate alloc] initWithDelegate:delegate];

    self.rewardedAd = [[AdnFullscreenAdController alloc] init];
    self.rewardedAd.fullscreenAdDelegate = self.rewardedAdDelegate;

    AdnFullscreenAdOptions *options = [[AdnFullscreenAdOptions alloc] initWithPlacement:AdnPlacementTypeRewarded
                                                                               adMarkup:adData.serverData];

    [self.rewardedAd loadAdWithOptions:options
                            completion:^(NSError *_Nullable error) {
        if (error) {
            LogAdapterDelegate_Internal(logError, error.description);
            ISAdapterErrorType errorType = (error.code == voodooNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        [delegate adDidLoad];
    }];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    [self.rewardedAd presentAdFrom:viewController];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && [self.rewardedAd canShow];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    [self.rewardedAd cleanUp];
    self.rewardedAd.fullscreenAdDelegate = nil;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISVoodooAdapter *adapter = (ISVoodooAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate
                              placementType:AdnPlacementTypeRewarded];
}

@end
