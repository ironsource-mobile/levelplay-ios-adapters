//
//  ISHyprMXRewardedAdapter.m
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <HyprMX/HyprMX.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISHyprMXRewardedAdapter.h"
#import "ISHyprMXRewardedDelegate.h"
#import "ISHyprMXAdapter+Internal.h"
#import "ISHyprMXAdapter.h"
#import "ISHyprMXConstants.h"

static ISConcurrentMutableSet *rewardedPropertyIdsInUse = nil;

@interface ISHyprMXRewardedAdapter ()

@property (nonatomic, strong) HyprMXPlacement          *rewardedAd;
@property (nonatomic, strong) ISHyprMXRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, copy, nullable) NSString         *reservedPropertyId;

@end

@implementation ISHyprMXRewardedAdapter

+ (void)initialize {
    if (self == [ISHyprMXRewardedAdapter class]) {
        rewardedPropertyIdsInUse = [ISConcurrentMutableSet set];
    }
}

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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

    if ([rewardedPropertyIdsInUse hasObject:propertyId]) {
        LogAdapterApi_Internal(logError, errorRewardedAdInUse);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:errorRewardedAdInUse];
        return;
    }

    [rewardedPropertyIdsInUse addObject:propertyId];
    self.reservedPropertyId = propertyId;

    HyprMXPlacement *placement = [HyprMX getPlacement:propertyId];
    if (placement == nil) {
        [rewardedPropertyIdsInUse removeObject:propertyId];
        self.reservedPropertyId = nil;
        LogAdapterApi_Internal(logError, logLoadNoFill);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                     errorCode:ERROR_RV_LOAD_NO_FILL
                                  errorMessage:logLoadNoFill];
        return;
    }

    self.rewardedAdDelegate = [[ISHyprMXRewardedDelegate alloc] initWithDelegate:delegate];
    placement.expiredDelegate = self.rewardedAdDelegate;
    self.rewardedAd = placement;

    void (^completionBlock)(BOOL) = ^(BOOL success) {
        if (success) {
            [delegate adDidLoad];
        } else {
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                         errorCode:ERROR_RV_LOAD_NO_FILL
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
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *propertyId = [adData getString:propertyIdKey];
    LogAdapterApi_Internal(logPropertyId, propertyId);

    if (self.reservedPropertyId) {
        [rewardedPropertyIdsInUse removeObject:self.reservedPropertyId];
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

    [self.rewardedAd showAdFromViewController:viewController
                                     delegate:self.rewardedAdDelegate];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && [self.rewardedAd isAdAvailable];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (self.reservedPropertyId) {
        [rewardedPropertyIdsInUse removeObject:self.reservedPropertyId];
        self.reservedPropertyId = nil;
    }
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
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
