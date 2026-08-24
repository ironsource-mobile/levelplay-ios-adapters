//
//  ISAPSBannerDelegate.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBannerAdDelegate.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISAPSBannerDelegate.h"
#import "ISAPSAdapter+Internal.h"

@implementation ISAPSBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)adDidLoad:(UIView *_Nonnull)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoadWithView:adView];
}

- (void)adFailedToLoad:(UIView *_Nullable)banner errorCode:(NSInteger)errorCode {
    NSString *errorReason = [NSString stringWithFormat:logErrorReason, [ISAPSAdapter errorFromCode:(DTBAdErrorCode)errorCode]];
    LogAdapterDelegate_Internal(logError, errorReason);

    BOOL isNoFill = errorCode == SampleErrorCodeNoInventory;
    [self.delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                      errorCode:(isNoFill ? ERROR_BN_LOAD_NO_FILL : errorCode)
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

- (void)bannerWillLeaveApplication:(UIView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

@end
