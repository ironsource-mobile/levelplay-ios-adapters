//
//  ISBidMachineRewardedDelegate.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISBidMachineRewardedDelegate.h"
#import "ISBidMachineRewardedAdapter.h"
#import "ISBidMachineConstants.h"
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBaseRewardedVideo.h>

@implementation ISBidMachineRewardedDelegate

- (instancetype)initWithAdapter:(ISBidMachineRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)rewardedDidPresent:(BidMachineRewarded * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
}

- (void)rewardedDidTrackImpression:(BidMachineRewarded * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidOpen];
}

- (void)rewardedDidFailPresent:(BidMachineRewarded * _Nonnull)ad
                             error:(BidMachineError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error.description);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)rewardedDidClick:(BidMachineRewarded * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClick];
}

- (void)rewardedDidReceiveReward:(BidMachineRewarded * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adRewarded];
}

- (void)rewardedDidExpire:(BidMachineRewarded * _Nonnull)ad {
    LogAdapterDelegate_Internal(logAdExpired);
    [self.adapter releaseAd];
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeAdExpired
                                      errorCode:ISAdapterErrorAdExpired
                                   errorMessage:logAdExpired];
}

- (void)rewardedDidDismiss:(BidMachineRewarded * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClose];
}

@end

