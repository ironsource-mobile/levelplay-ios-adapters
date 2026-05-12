//
//  ISBidMachineBannerDelegate.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISBidMachineBannerDelegate.h"
#import "ISBidMachineConstants.h"
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISBannerAdDelegate.h>

@implementation ISBidMachineBannerDelegate

- (instancetype)initWithBanner:(BidMachineBanner *)banner
                      delegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];

    if (self) {
        _banner = banner;
        _delegate = delegate;
    }

    return self;
}

- (void)didLoadAd:(id <BidMachineAdProtocol> _Nonnull)ad {
    NSString *creativeId = ad.auctionInfo.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);
    if (creativeId.length) {
        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithView:self.banner
                               extraData:extraData];
    } else {
        [self.delegate adDidLoadWithView:self.banner];
    }
}

- (void)didFailLoadAd:(id <BidMachineAdProtocol> _Nonnull)ad
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

- (void)didUserInteraction:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClick];
}

@end
