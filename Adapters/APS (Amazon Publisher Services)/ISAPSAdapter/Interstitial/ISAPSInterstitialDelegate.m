//
//  ISAPSInterstitialDelegate.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISAPSInterstitialDelegate.h"
#import "ISAPSAdapter+Internal.h"

@implementation ISAPSInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)interstitialDidLoad:(DTBAdInterstitialDispatcher *_Nullable)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

- (void)interstitial:(DTBAdInterstitialDispatcher *_Nullable)interstitial
    didFailToLoadAdWithErrorCode:(DTBAdErrorCode)errorCode {
    NSString *errorReason = [NSString stringWithFormat:logErrorReason, [ISAPSAdapter errorFromCode:errorCode]];
    LogAdapterDelegate_Internal(logError, errorReason);

    BOOL isNoFill = errorCode == SampleErrorCodeNoInventory;
    [self.delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                      errorCode:(isNoFill ? ERROR_IS_LOAD_NO_FILL : (NSInteger)errorCode)
                                   errorMessage:errorReason];
}

- (void)impressionFired {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)adClicked {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)interstitialDidDismissScreen:(DTBAdInterstitialDispatcher *_Nullable)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)interstitialWillPresentScreen:(DTBAdInterstitialDispatcher *_Nullable)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialDidPresentScreen:(DTBAdInterstitialDispatcher *_Nullable)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialWillDismissScreen:(DTBAdInterstitialDispatcher *_Nullable)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialWillLeaveApplication:(DTBAdInterstitialDispatcher *_Nullable)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)showFromRootViewController:(UIViewController *_Nonnull)controller {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
