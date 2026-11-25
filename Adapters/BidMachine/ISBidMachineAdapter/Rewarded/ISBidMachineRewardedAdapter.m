//
//  ISBidMachineRewardedAdapter.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISBidMachineRewardedAdapter.h"
#import "ISBidMachineRewardedDelegate.h"
#import "ISBidMachineAdapter+Internal.h"
#import "ISBidMachineAdapter.h"
#import "ISBidMachineConstants.h"

@interface ISBidMachineRewardedAdapter ()

@property (nonatomic, strong) BidMachineRewarded           *rewardedAd;
@property (nonatomic, strong) ISBidMachineRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISBidMachineRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    __weak ISBidMachineRewardedAdapter *weakSelf = self;
    void (^completion)(BidMachineRewarded * _Nullable, BidMachineError * _Nullable) = ^(BidMachineRewarded * _Nullable rewarded, BidMachineError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error || !rewarded) {
            NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
            NSString *description = error ? error.description : [NSString stringWithFormat:logLoadFailed, networkName];
            ISAdapterErrorType errorType = (code == BidMachineErrorCodeNoContent) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            LogInternal_Error(logError, description);
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:code
                                      errorMessage:description];
            return;
        }

        if (!strongSelf) {
            LogInternal_Error(logError, logAdapterNil);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ISAdapterErrorInternal
                                      errorMessage:logAdapterNil];
            return;
        }

        strongSelf.rewardedAdDelegate = [[ISBidMachineRewardedDelegate alloc] initWithAdapter:strongSelf
                                                                                             delegate:delegate];
        strongSelf.rewardedAd = rewarded;
        strongSelf.rewardedAd.delegate = strongSelf.rewardedAdDelegate;

        NSString *creativeId = rewarded.auctionInfo.creativeId;
        LogAdapterDelegate_Internal(logCreativeId, creativeId);
        if (creativeId.length) {
            NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
            [delegate adDidLoadWithExtraData:extraData];
        } else {
            [delegate adDidLoad];
        }
    };

    BidMachineInstance *instance = ISBidMachineAdapter.bidMachineInstance;
    if (adData.serverData.length > 0) {
        [instance loadRewardedWithPayload:adData.serverData
                                   completion:completion];
    } else {
        BidMachinePlacement *placement = nil;
        if (placementId.length > 0) {
            placement = [[BidMachinePlacement alloc] initWithId:placementId extras:@{}];
        }
        [instance loadRewardedWithPlacement:placement
                                     completion:completion];
    }
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logEmptyCallback);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isAdAvailableWithAdData:adData]) {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                      withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
            LogAdapterApi_Internal(logError, error);
            [delegate adDidFailToShowWithErrorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        [self.rewardedAd showFrom:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd && [self.rewardedAd canShow];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logEmptyCallback);
    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)releaseAd {
    self.rewardedAd = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    ISBidMachineAdapter *adapter = (ISBidMachineAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    
    [adapter collectBiddingDataWithPlacementId:placementId
                                      delegate:delegate];
}

@end
