//
//  ISPangleInterstitialDelegate.m
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseInterstitial.h>
#import "ISPangleInterstitialDelegate.h"
#import "ISPangleConstants.h"

@implementation ISPangleInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark PAGLInterstitialAdDelegate Delegates

/// This method is invoked when the ad is displayed, covering the device's screen.
- (void)adDidShow:(id<PAGAdProtocol>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// This method is invoked when the ad is clicked by the user.
- (void)adDidClick:(id<PAGAdProtocol>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// This method is invoked when the ad disappears.
- (void)adDidDismiss:(id<PAGAdProtocol>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
