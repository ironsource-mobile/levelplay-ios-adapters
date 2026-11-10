//
//  ISHyprMXInterstitialAdapter.m
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <HyprMX/HyprMX.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISHyprMXInterstitialAdapter.h"
#import "ISHyprMXInterstitialDelegate.h"
#import "ISHyprMXAdapter+Internal.h"
#import "ISHyprMXAdapter.h"
#import "ISHyprMXConstants.h"

static ISConcurrentMutableSet *interstitialPropertyIdsInUse = nil;

@interface ISHyprMXInterstitialAdapter ()

@property (nonatomic, strong) HyprMXPlacement              *interstitialAd;
@property (nonatomic, strong) ISHyprMXInterstitialDelegate *interstitialAdDelegate;
@property (nonatomic, copy, nullable) NSString             *reservedPropertyId;

@end

@implementation ISHyprMXInterstitialAdapter

+ (void)initialize {
    if (self == [ISHyprMXInterstitialAdapter class]) {
        interstitialPropertyIdsInUse = [ISConcurrentMutableSet set];
    }
}

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *propertyId = [adData getString:propertyIdKey];
    LogAdapterApi_Internal(logPropertyId, propertyId);

    if (!propertyId || propertyId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, propertyIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    if ([interstitialPropertyIdsInUse hasObject:propertyId]) {
        LogAdapterApi_Internal(logError, errorInterstitialAdInUse);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:errorInterstitialAdInUse];
        return;
    }

    [interstitialPropertyIdsInUse addObject:propertyId];
    self.reservedPropertyId = propertyId;

    HyprMXPlacement *placement = [HyprMX getPlacement:propertyId];
    if (placement == nil) {
        [interstitialPropertyIdsInUse removeObject:propertyId];
        self.reservedPropertyId = nil;
        LogAdapterApi_Internal(logError, logLoadNoFill);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                     errorCode:ERROR_IS_LOAD_NO_FILL
                                  errorMessage:logLoadNoFill];
        return;
    }

    self.interstitialAdDelegate = [[ISHyprMXInterstitialDelegate alloc] initWithDelegate:delegate];
    placement.expiredDelegate = self.interstitialAdDelegate;
    self.interstitialAd = placement;

    void (^completionBlock)(BOOL) = ^(BOOL success) {
        if (success) {
            [delegate adDidLoad];
        } else {
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                         errorCode:ERROR_IS_LOAD_NO_FILL
                                      errorMessage:logLoadNoFill];
        }
    };

    if (adData.serverData) {
        [placement loadAdWithBidResponse:adData.serverData completion:completionBlock];
    } else {
        [placement loadAdWithCompletion:completionBlock];
    }
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *propertyId = [adData getString:propertyIdKey];
    LogAdapterApi_Internal(logPropertyId, propertyId);

    if (self.reservedPropertyId) {
        [interstitialPropertyIdsInUse removeObject:self.reservedPropertyId];
        self.reservedPropertyId = nil;
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

    [self.interstitialAd showAdFromViewController:viewController
                                         delegate:self.interstitialAdDelegate];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && [self.interstitialAd isAdAvailable];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (self.reservedPropertyId) {
        [interstitialPropertyIdsInUse removeObject:self.reservedPropertyId];
        self.reservedPropertyId = nil;
    }
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISHyprMXAdapter *adapter = (ISHyprMXAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
