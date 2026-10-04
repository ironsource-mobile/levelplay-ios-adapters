//
//  ISAdMobBannerAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/LPMAdSize.h>
#import "ISAdMobBannerAdapter.h"
#import "ISAdMobBannerDelegate.h"
#import "ISAdMobAdapter+Internal.h"
#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"

@interface ISAdMobBannerAdapter ()

@property (nonatomic, strong) GADBannerView                 *bannerAdView;
@property (nonatomic, strong) ISAdMobBannerDelegate         *bannerAdViewDelegate;

@end

@implementation ISAdMobBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISAdMobAdapter *adapter = (ISAdMobAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isBannerSizeSupported:size]) {
            NSError *error = [NSError errorWithDomain:networkName
                                                 code:ERROR_BN_UNSUPPORTED_SIZE
                                             userInfo:@{NSLocalizedDescriptionKey:logUnsupportedBannerSize}];
            LogAdapterApi_Internal(logError, error);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        GADAdSize adMobSize = [self getBannerSize:size];
        GADBannerView *banner = [[GADBannerView alloc] initWithAdSize:adMobSize];
        self.bannerAdViewDelegate = [[ISAdMobBannerDelegate alloc] initWithDelegate:delegate];
        banner.delegate = self.bannerAdViewDelegate;
        banner.adUnitID = adUnitId;
        banner.rootViewController = viewController;
        self.bannerAdView = banner;

        if (adData.serverData) {
            [banner loadWithAdResponseString:adData.serverData];
        } else {
            GADRequest *request = [adapter createGADRequestWithAdData:adData.adUnitData];
            [banner loadRequest:request];
        }
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView.delegate = nil;
        [self.bannerAdView removeFromSuperview];
        self.bannerAdView = nil;
        self.bannerAdViewDelegate = nil;
    });
}

- (BOOL)isSupportAdaptiveBanner {
    return YES;
}

#pragma mark - Bidding Data

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISAdMobAdapter *adapter = (ISAdMobAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    GADSignalRequest *request = [self createBannerSignalRequestWithAdData:adData];

    [adapter collectBiddingDataWithSignalRequest:request
                                          adData:adData
                                        delegate:delegate];
}

#pragma mark - Helper Methods

- (GADSignalRequest *)createBannerSignalRequestWithAdData:(ISAdData *)adData {
    GADBannerSignalRequest *bannerRequest = [[GADBannerSignalRequest alloc] initWithSignalType:requesterType];

    ISBannerSize *size = [adData.adUnitData objectForKey:bannerSizeKey];
    if (size) {
        GADAdSize adSize = [self getBannerSize:size];
        bannerRequest.adSize = adSize;
    }

    return bannerRequest;
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    return ([size.sizeDescription isEqualToString:sizeBanner] ||
            [size.sizeDescription isEqualToString:sizeLarge] ||
            [size.sizeDescription isEqualToString:sizeRectangle] ||
            [size.sizeDescription isEqualToString:sizeSmart] ||
            [size.sizeDescription isEqualToString:sizeCustom]);
}

- (GADAdSize)getBannerSize:(ISBannerSize *)size {
    GADAdSize adMobSize = GADAdSizeInvalid;

    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        adMobSize = GADAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:sizeLarge]) {
        adMobSize = GADAdSizeLargeBanner;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        adMobSize = GADAdSizeMediumRectangle;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        adMobSize = [self isLargeScreen] ? GADAdSizeLeaderboard : GADAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        adMobSize = GADAdSizeFromCGSize(CGSizeMake(size.width, size.height));
    }

    if (size.isAdaptive) {
        LPMAdSize *adaptiveSize = [size toLPMAdSize];
        adMobSize = [self getAdmobAdaptiveAdSizeWithWidth:adaptiveSize.width];
    }

    return adMobSize;
}

- (GADAdSize)getAdmobAdaptiveAdSizeWithWidth:(CGFloat)width {
    __block GADAdSize adaptiveSize;

    void (^calculateAdaptiveSize)(void) = ^{
        adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width);
    };

    if ([NSThread isMainThread]) {
        calculateAdaptiveSize();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            calculateAdaptiveSize();
        });
    }

    return adaptiveSize;
}

- (BOOL)isLargeScreen {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

@end
