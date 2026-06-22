//
//  ISHyprMXInterstitialDelegate.m
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBaseInterstitial.h>
#import "ISHyprMXInterstitialDelegate.h"
#import "ISHyprMXConstants.h"

@implementation ISHyprMXInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - HyprMXPlacementShowDelegate

- (void)adWillStartForPlacement:(HyprMXPlacement *)placement {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)adImpression:(HyprMXPlacement *)placement {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)adDisplayError:(NSError *)error
             placement:(HyprMXPlacement *)placement {
    LogAdapterDelegate_Internal(logError, error);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)adDidCloseForPlacement:(HyprMXPlacement *)placement
                   didFinishAd:(BOOL)finished {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

#pragma mark - HyprMXPlacementExpiredDelegate

- (void)adExpiredForPlacement:(HyprMXPlacement *)placement {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
