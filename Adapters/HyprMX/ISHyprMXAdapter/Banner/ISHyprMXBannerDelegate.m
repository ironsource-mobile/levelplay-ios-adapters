//
//  ISHyprMXBannerDelegate.m
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBannerAdDelegate.h>
#import "ISHyprMXBannerDelegate.h"
#import "ISHyprMXConstants.h"

@implementation ISHyprMXBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - HyprMXBannerDelegate

- (void)adImpression:(HyprMXBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)adWasClicked:(HyprMXBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)adDidOpen:(HyprMXBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

- (void)adDidClose:(HyprMXBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

@end
