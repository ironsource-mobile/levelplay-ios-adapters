//
//  ISAppLovinRewardedAdapter.m
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISAppLovinRewardedAdapter.h"
#import "ISAppLovinRewardedDelegate.h"
#import "ISAppLovinAdapter+Internal.h"

static ISConcurrentMutableSet *rewardedZoneIdsInUse = nil;

@interface ISAppLovinRewardedAdapter ()

@property (nonatomic, strong) ALIncentivizedInterstitialAd *rewardedAd;
@property (nonatomic, strong) ALAd *loadedAd;
@property (nonatomic, strong) ISAppLovinRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, copy, nullable) NSString *reservedZoneId;

@end

@implementation ISAppLovinRewardedAdapter

+ (void)initialize {
    if (self == [ISAppLovinRewardedAdapter class]) {
        rewardedZoneIdsInUse = [ISConcurrentMutableSet set];
    }
}

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *zoneId = [adData getString:zoneIdKey];
    LogAdapterApi_Internal(logZoneId, zoneId);

    if (!zoneId || zoneId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, zoneIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    if ([rewardedZoneIdsInUse hasObject:zoneId]) {
        LogAdapterApi_Internal(logError, errorRewardedAdInUse);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:errorRewardedAdInUse];
        return;
    }

    [rewardedZoneIdsInUse addObject:zoneId];
    self.reservedZoneId = zoneId;

    self.rewardedAdDelegate = [[ISAppLovinRewardedDelegate alloc] initWithAdapter:self
                                                                        delegate:delegate];
    self.rewardedAd = [[ALIncentivizedInterstitialAd alloc] initWithZoneIdentifier:zoneId];

    if (self.rewardedAd == nil) {
        NSString *errorMessage = [NSString stringWithFormat:logAdCreationFailed, networkName];
        LogAdapterApi_Internal(logError, errorMessage);

        if (self.reservedZoneId) {
            [rewardedZoneIdsInUse removeObject:self.reservedZoneId];
            self.reservedZoneId = nil;
        }

        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:errorMessage];
        return;
    }

    self.rewardedAd.adDisplayDelegate = self.rewardedAdDelegate;
    self.rewardedAd.adVideoPlaybackDelegate = self.rewardedAdDelegate;

    [ALSdk.shared.adService loadNextAdForZoneIdentifier:zoneId
                                              andNotify:self.rewardedAdDelegate];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *zoneId = [adData getString:zoneIdKey];
    LogAdapterApi_Internal(logZoneId, zoneId);

    if (self.reservedZoneId) {
        [rewardedZoneIdsInUse removeObject:self.reservedZoneId];
        self.reservedZoneId = nil;
    }

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    NSString *userId = [self dynamicUserId];

    if (userId.length) {
        LogAdapterApi_Internal(logSetUserId, userId);
        [ALSdk shared].settings.userIdentifier = userId;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd showAd:self.loadedAd
                      andNotify:self.rewardedAdDelegate];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.loadedAd != nil;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (self.reservedZoneId) {
        [rewardedZoneIdsInUse removeObject:self.reservedZoneId];
        self.reservedZoneId = nil;
    }
    self.rewardedAd = nil;
    self.loadedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)setLoadedAd:(ALAd *)ad {
    _loadedAd = ad;
}

@end
