//
//  ISYandexBannerAdapter.m
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

@import YandexMobileAds;
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISYandexBannerAdapter.h"
#import "ISYandexBannerDelegate.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"

@interface ISYandexBannerAdapter ()

@property (nonatomic, strong) YMABannerAdView *bannerAdView;
@property (nonatomic, strong) ISYandexBannerDelegate *bannerAdDelegate;

@end

@implementation ISYandexBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    // validate adUnitId
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

    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    // get size
    YMABannerAdSize *adSize = [self getBannerSize:size];

    // create banner ad delegate
    self.bannerAdDelegate = [[ISYandexBannerDelegate alloc] initWithDelegate:delegate];

    // get ad request parameters from adapter
    YMAAdRequest *adRequest = [adapter createAdRequestWithBidResponse:adData.serverData
                                                              adUnitId:adUnitId];

    dispatch_async(dispatch_get_main_queue(), ^{
        // create banner view
        self.bannerAdView = [[YMABannerAdView alloc] initWithAdSize:adSize];
        self.bannerAdView.delegate = self.bannerAdDelegate;

        // load ad
        [self.bannerAdView loadAdWithRequest:adRequest];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView.delegate = nil;
        self.bannerAdView = nil;
        self.bannerAdDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    YMABidderTokenRequest *requestConfiguration = nil;
    NSDictionary *adUnitData = adData.adUnitData;
    if ([adUnitData objectForKey:bannerSizeKey]) {
        ISBannerSize *size = [adUnitData objectForKey:bannerSizeKey];
        YMABannerAdSize *adSize = [self getBannerSize:size];
        requestConfiguration = [YMABidderTokenRequest bannerWithSize:adSize
                                                            targeting:nil
                                                           parameters:[adapter getConfigParams]];
    } else {
        // Create a default banner size if none specified
        YMABannerAdSize *defaultSize = [YMABannerAdSize fixedWithWidth:bannerWidth height:bannerHeight];
        requestConfiguration = [YMABidderTokenRequest bannerWithSize:defaultSize
                                                            targeting:nil
                                                           parameters:[adapter getConfigParams]];
    }

    [adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                delegate:delegate];
}

- (YMABannerAdSize *)getBannerSize:(ISBannerSize *)size {
    YMABannerAdSize *adSize = nil;

    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        adSize = [YMABannerAdSize fixedWithWidth:bannerWidth height:bannerHeight];
    } else if ([size.sizeDescription isEqualToString:sizeLarge]) {
        adSize = [YMABannerAdSize fixedWithWidth:largeBannerWidth height:largeBannerHeight];
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        adSize = [YMABannerAdSize fixedWithWidth:rectangleWidth height:rectangleHeight];
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            adSize = [YMABannerAdSize fixedWithWidth:leaderboardWidth height:leaderboardHeight];
        } else {
            adSize = [YMABannerAdSize fixedWithWidth:bannerWidth height:bannerHeight];
        }
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        adSize = [YMABannerAdSize fixedWithWidth:size.width height:size.height];
    }

    return adSize;
}

@end
