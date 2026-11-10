//
//  ISMintegralRewardedAdapter.m
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDKBidding/MTGBiddingSDK.h>
#import <MTGSDKReward/MTGBidRewardAdManager.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISMintegralRewardedAdapter.h"
#import "ISMintegralRewardedDelegate.h"
#import "ISMintegralAdapter+Internal.h"
#import "ISMintegralAdapter.h"
#import "ISMintegralConstants.h"

static ISConcurrentMutableSet *rewardedPlacementIdsInUse = nil;

@interface ISMintegralRewardedAdapter ()

@property (nonatomic, strong) ISMintegralRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, copy, nullable) NSString *reservedPlacementId;

@end

@implementation ISMintegralRewardedAdapter

+ (void)initialize {
    if (self == [ISMintegralRewardedAdapter class]) {
        rewardedPlacementIdsInUse = [ISConcurrentMutableSet set];
    }
}

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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

    if ([rewardedPlacementIdsInUse hasObject:placementId]) {
        LogAdapterApi_Internal(logError, errorRewardedAdInUse);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:errorRewardedAdInUse];
        return;
    }

    [rewardedPlacementIdsInUse addObject:placementId];
    self.reservedPlacementId = placementId;

    self.rewardedAdDelegate = [[ISMintegralRewardedDelegate alloc] initWithDelegate:delegate];

    [[MTGBidRewardAdManager sharedInstance] loadVideoWithBidToken:adData.serverData
                                                      placementId:placementId
                                                           unitId:unitId
                                                         delegate:self.rewardedAdDelegate];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    NSString *unitId = [adData getString:unitIdKey];
    LogAdapterApi_Internal(logPlacementIdAndUnitId, placementId, unitId);

    if (self.reservedPlacementId) {
        [rewardedPlacementIdsInUse removeObject:self.reservedPlacementId];
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
        [[MTGBidRewardAdManager sharedInstance] showVideoWithPlacementId:placementId
                                                                 unitId:unitId
                                                                 userId:[self dynamicUserId]
                                                               delegate:self.rewardedAdDelegate
                                                         viewController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    NSString *placementId = [adData getString:placementIdKey];
    NSString *unitId = [adData getString:unitIdKey];
    return [[MTGBidRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId:placementId
                                                                             unitId:unitId];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (self.reservedPlacementId) {
        [rewardedPlacementIdsInUse removeObject:self.reservedPlacementId];
        self.reservedPlacementId = nil;
    }
    self.rewardedAdDelegate = nil;
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
                                        adType:MintegralRewardVideoAd
                                      delegate:delegate];
}

@end
