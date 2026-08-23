//
//  ISAppLovinInterstitialAdapter.m
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISAppLovinInterstitialAdapter.h"
#import "ISAppLovinInterstitialDelegate.h"
#import "ISAppLovinAdapter+Internal.h"

static ISConcurrentMutableSet *interstitialZoneIdsInUse = nil;

@interface ISAppLovinInterstitialAdapter ()

@property (nonatomic, strong) ALInterstitialAd *interstitialAd;
@property (nonatomic, strong) ALAd *loadedAd;
@property (nonatomic, strong) ISAppLovinInterstitialDelegate *interstitialAdDelegate;
@property (nonatomic, copy, nullable) NSString *reservedZoneId;

@end

@implementation ISAppLovinInterstitialAdapter

+ (void)initialize {
    if (self == [ISAppLovinInterstitialAdapter class]) {
        interstitialZoneIdsInUse = [ISConcurrentMutableSet set];
    }
}

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
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

    if ([interstitialZoneIdsInUse hasObject:zoneId]) {
        LogAdapterApi_Internal(logError, errorInterstitialAdInUse);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:errorInterstitialAdInUse];
        return;
    }

    [interstitialZoneIdsInUse addObject:zoneId];
    self.reservedZoneId = zoneId;

    self.interstitialAdDelegate = [[ISAppLovinInterstitialDelegate alloc] initWithAdapter:self
                                                                                delegate:delegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = [[ALInterstitialAd alloc] init];

        if (self.interstitialAd == nil) {
            NSString *errorMessage = [NSString stringWithFormat:logAdCreationFailed, networkName];
            LogAdapterApi_Internal(logError, errorMessage);

            if (self.reservedZoneId) {
                [interstitialZoneIdsInUse removeObject:self.reservedZoneId];
                self.reservedZoneId = nil;
            }

            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ERROR_CODE_GENERIC
                                      errorMessage:errorMessage];
            return;
        }

        self.interstitialAd.adDisplayDelegate = self.interstitialAdDelegate;
        self.interstitialAd.adLoadDelegate = self.interstitialAdDelegate;

        [ALSdk.shared.adService loadNextAdForZoneIdentifier:zoneId
                                                  andNotify:self.interstitialAdDelegate];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *zoneId = [adData getString:zoneIdKey];
    LogAdapterApi_Internal(logZoneId, zoneId);

    if (self.reservedZoneId) {
        [interstitialZoneIdsInUse removeObject:self.reservedZoneId];
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

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showAd:self.loadedAd];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.loadedAd != nil;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (self.reservedZoneId) {
        [interstitialZoneIdsInUse removeObject:self.reservedZoneId];
        self.reservedZoneId = nil;
    }
    self.interstitialAd = nil;
    self.loadedAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)setLoadedAd:(ALAd *)ad {
    _loadedAd = ad;
}

@end
