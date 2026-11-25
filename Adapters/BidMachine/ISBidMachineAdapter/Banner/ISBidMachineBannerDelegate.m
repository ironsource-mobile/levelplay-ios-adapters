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

- (void)bannerDidPresent:(BidMachineBanner * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
}

- (void)bannerDidTrackImpression:(BidMachineBanner * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidOpen];
}

- (void)bannerDidFailPresent:(BidMachineBanner * _Nonnull)ad
                       error:(BidMachineError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error.description);
}

- (void)bannerDidClick:(BidMachineBanner * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClick];
}

@end
