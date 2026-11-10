//
//  ISBidMachineRewardedDelegate.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISBidMachineRewardedDelegate.h"
#import "ISBidMachineConstants.h"
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISBaseRewardedVideo.h>

@implementation ISBidMachineRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)didLoadAd:(id<BidMachineAdProtocol> _Nonnull)ad {
    NSString *creativeId = ad.auctionInfo.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);
    if (creativeId.length) {
        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithExtraData:extraData];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)didFailLoadAd:(id<BidMachineAdProtocol> _Nonnull)ad
                     :(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error.description);
    ISAdapterErrorType errorType = (error.code == bidMachineNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)didTrackImpression:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidOpen];
}

- (void)didFailPresentAd:(id <BidMachineAdProtocol> _Nonnull)ad
                        :(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error.description);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)didUserInteraction:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClick];
}

- (void)didReceiveReward:(id<BidMachineAdProtocol>)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adRewarded];
}

- (void)didDismissAd:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClose];
}

@end

