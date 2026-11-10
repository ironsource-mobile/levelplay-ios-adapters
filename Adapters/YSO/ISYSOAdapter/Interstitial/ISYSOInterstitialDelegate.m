//
//  ISYSOInterstitialDelegate.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISYSOInterstitialDelegate.h"
#import "ISYSOAdapter+Internal.h"

@implementation ISYSOInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Callback Handlers

- (void)handleOnLoad:(e_ActionError)error {
    if (error == e_ActionErrorNone) {
        LogAdapterDelegate_Internal(logCallbackEmpty);
        [self.delegate adDidLoad];
        return;
    }

    NSString *loadError = [ISYSOAdapter loadErrorToString:error];
    LogAdapterDelegate_Internal(logError, loadError);
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:(NSInteger)error
                                   errorMessage:loadError];
}

- (void)handleOnDisplay:(YNWebView *)view {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)handleOnClick {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)handleOnClose:(BOOL)display complete:(BOOL)complete {
    if (!display) {
        NSString *errorMessage = [NSString stringWithFormat:logShowFailed, networkName];
        LogAdapterDelegate_Internal(logError, errorMessage);
        [self.delegate adDidFailToShowWithErrorCode:ERROR_CODE_GENERIC
                                       errorMessage:errorMessage];
        return;
    }

    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
