//
//  ISMintegralInterstitialAdapter.m
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDKBidding/MTGBiddingSDK.h>
#import <MTGSDKNewInterstitial/MTGNewInterstitialBidAdManager.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISMintegralInterstitialAdapter.h"
#import "ISMintegralInterstitialDelegate.h"
#import "ISMintegralAdapter+Internal.h"
#import "ISMintegralAdapter.h"
#import "ISMintegralConstants.h"

static ISConcurrentMutableSet *interstitialPlacementIdsInUse = nil;

@interface ISMintegralInterstitialAdapter ()

@property (nonatomic, strong) MTGNewInterstitialBidAdManager  *interstitialAd;
@property (nonatomic, strong) ISMintegralInterstitialDelegate *interstitialAdDelegate;
@property (nonatomic, copy, nullable) NSString *reservedPlacementId;

@end

@implementation ISMintegralInterstitialAdapter

+ (void)initialize {
    if (self == [ISMintegralInterstitialAdapter class]) {
        interstitialPlacementIdsInUse = [ISConcurrentMutableSet set];
    }
}

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    NSString *unitId = [adData getString:unitIdKey];
    LogAdapterApi_Internal(logPlacementIdAndUnitId, placementId, unitId);

    if (!unitId || unitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, unitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    if ([interstitialPlacementIdsInUse hasObject:placementId]) {
        LogAdapterApi_Internal(logError, errorInterstitialAdInUse);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:errorInterstitialAdInUse];
        return;
    }

    [interstitialPlacementIdsInUse addObject:placementId];
    self.reservedPlacementId = placementId;

    self.interstitialAdDelegate = [[ISMintegralInterstitialDelegate alloc] initWithDelegate:delegate];

    self.interstitialAd = [[MTGNewInterstitialBidAdManager alloc] initWithPlacementId:placementId
                                                                               unitId:unitId
                                                                             delegate:self.interstitialAdDelegate];
    [self.interstitialAd loadAdWithBidToken:adData.serverData];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (self.reservedPlacementId) {
        [interstitialPlacementIdsInUse removeObject:self.reservedPlacementId];
        self.reservedPlacementId = nil;
    }

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
        [self.interstitialAd showFromViewController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && [self.interstitialAd isAdReady];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (self.reservedPlacementId) {
        [interstitialPlacementIdsInUse removeObject:self.reservedPlacementId];
        self.reservedPlacementId = nil;
    }
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    NSString *unitId = [adData getString:unitIdKey];

    ISMintegralAdapter *adapter = (ISMintegralAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithPlacementId:placementId
                                        unitId:unitId
                                        adType:MintegralIntersitialAd
                                      delegate:delegate];
}

@end
