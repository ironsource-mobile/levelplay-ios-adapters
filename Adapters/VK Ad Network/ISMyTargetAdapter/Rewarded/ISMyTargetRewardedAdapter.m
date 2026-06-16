//
//  ISMyTargetRewardedAdapter.m
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MyTargetSDK/MyTargetSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMyTargetRewardedAdapter.h"
#import "ISMyTargetRewardedDelegate.h"
#import "ISMyTargetAdapter+Internal.h"
#import "ISMyTargetAdapter.h"
#import "ISMyTargetConstants.h"

@interface ISMyTargetRewardedAdapter ()

@property (nonatomic, strong) MTRGRewardedAd             *rewardedAd;
@property (nonatomic, strong) ISMyTargetRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISMyTargetRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    if (!slotId || slotId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, slotIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    self.adAvailability = NO;

    self.rewardedAdDelegate = [[ISMyTargetRewardedDelegate alloc] initWithAdapter:self
                                                                         delegate:delegate];

    self.rewardedAd = [MTRGRewardedAd rewardedAdWithSlotId:slotId.integerValue];
    [self.rewardedAd.customParams setCustomParam:mediationParamValue forKey:mediationParamKey];
    [self.rewardedAd setDelegate:self.rewardedAdDelegate];

    NSString *serverData = adData.serverData;
    if (serverData.length) {
        [self.rewardedAd loadFromBid:serverData];
    } else {
        [self.rewardedAd load];
    }
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
        [self.rewardedAd showWithController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.adAvailability;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)setRewardedAdAvailability:(BOOL)availability {
    self.adAvailability = availability;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISMyTargetAdapter *adapter = (ISMyTargetAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
