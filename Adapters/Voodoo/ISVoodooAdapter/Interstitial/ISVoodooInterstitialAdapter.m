//
//  ISVoodooInterstitialAdapter.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISVoodooInterstitialAdapter.h"
#import "ISVoodooInterstitialDelegate.h"
#import "ISVoodooAdapter+Internal.h"

@interface ISVoodooInterstitialAdapter ()

@property (nonatomic, strong) AdnFullscreenAdController *interstitialAd;
@property (nonatomic, strong) ISVoodooInterstitialDelegate *interstitialAdDelegate;

@end

@implementation ISVoodooInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    self.interstitialAdDelegate = [[ISVoodooInterstitialDelegate alloc] initWithDelegate:delegate];

    self.interstitialAd = [[AdnFullscreenAdController alloc] init];
    self.interstitialAd.fullscreenAdDelegate = self.interstitialAdDelegate;

    AdnFullscreenAdOptions *options = [[AdnFullscreenAdOptions alloc] initWithPlacement:AdnPlacementTypeInterstitial
                                                                               adMarkup:adData.serverData];

    [self.interstitialAd loadAdWithOptions:options
                                completion:^(NSError *_Nullable error) {
        if (error) {
            LogAdapterDelegate_Internal(logError, error.description);
            ISAdapterErrorType errorType = (error.code == voodooNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        [delegate adDidLoad];
    }];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    [self.interstitialAd presentAdFrom:viewController];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && [self.interstitialAd canShow];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    [self.interstitialAd cleanUp];
    self.interstitialAd.fullscreenAdDelegate = nil;
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISVoodooAdapter *adapter = (ISVoodooAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate
                              placementType:AdnPlacementTypeInterstitial];
}

@end
