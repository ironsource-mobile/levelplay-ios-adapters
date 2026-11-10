//
//  ISUnityAdsBannerAdapter.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISUnityAdsBannerAdapter.h"
#import "ISUnityAdsBannerDelegate.h"
#import "ISUnityAdsAdapter+Internal.h"

@interface ISUnityAdsBannerAdapter ()

@property (nonatomic, strong) UADSBannerAd *bannerAdView;
@property (nonatomic, strong) ISUnityAdsBannerDelegate *bannerAdDelegate;

@end

@implementation ISUnityAdsBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    if (![self isBannerSizeSupported:size]) {
        NSString *errorMessage = [NSString stringWithFormat:logUnsupportedBannerSize, size.sizeDescription];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_BN_UNSUPPORTED_SIZE
                                  errorMessage:errorMessage];
        return;
    }

    ISUnityAdsAdapter *adapter = (ISUnityAdsAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    self.bannerAdDelegate = [[ISUnityAdsBannerDelegate alloc] initWithDelegate:delegate];

    UADSBannerLoadConfigurationBuilder *builder = [[UADSBannerLoadConfigurationBuilder alloc]
                                                   initWithPlacementId:placementId
                                                            bannerSize:[self getBannerSize:size]
                                                              delegate:self.bannerAdDelegate];

    if (adData.serverData != nil) {
        builder = [builder withAdMarkup:adData.serverData];
    }

    builder = [builder withMediationInfo:[adapter adapterMediationInfo]];
    builder = [builder withMediationAdUnitId:placementId];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UADSBannerAd load:[builder build]
                completion:^(UADSBannerAd * _Nullable bannerAd, id<UnityAdsError> _Nullable error) {

            if (bannerAd == nil) {
                LogAdapterDelegate_Internal(logError, error.message);
                BOOL isNoFill = error.code == unityAdsNoFillErrorCode;
                [delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                             errorCode:(isNoFill ? ERROR_BN_LOAD_NO_FILL : error.code)
                                          errorMessage:error.message];
                return;
            }

            LogAdapterDelegate_Internal(logPlacementId, placementId);
            self.bannerAdView = bannerAd;
            [delegate adDidLoadWithView:bannerAd.view];
        }];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView = nil;
        self.bannerAdDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISUnityAdsAdapter *adapter = (ISUnityAdsAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithAdData:adData
                                 adFormat:UADSAdFormatBanner
                                 delegate:delegate];
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    return [size.sizeDescription isEqualToString:sizeBanner] ||
           [size.sizeDescription isEqualToString:sizeLarge] ||
           [size.sizeDescription isEqualToString:sizeRectangle] ||
           [size.sizeDescription isEqualToString:sizeSmart];
}

- (CGSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner] ||
        [size.sizeDescription isEqualToString:sizeLarge]) {
        return CGSizeMake(bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return CGSizeMake(rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return CGSizeMake(leaderboardWidth, leaderboardHeight);
        } else {
            return CGSizeMake(bannerWidth, bannerHeight);
        }
    }

    return CGSizeZero;
}

@end
