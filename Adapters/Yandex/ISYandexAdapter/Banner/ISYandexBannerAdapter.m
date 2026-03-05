//
//  ISYandexBannerAdapter.m
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISYandexBannerAdapter.h"
#import "ISYandexBannerDelegate.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"

@interface ISYandexBannerAdapter ()

@property (nonatomic, strong) YMAAdView *ad;
@property (nonatomic, strong) ISYandexBannerDelegate *yandexAdDelegate;

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
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingAdUnitId}];
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
    ISYandexBannerDelegate *adDelegate = [[ISYandexBannerDelegate alloc] initWithAdUnitId:adUnitId
                                                                              andDelegate:delegate];
    self.yandexAdDelegate = adDelegate;

    // get ad request parameters from adapter
    YMAMutableAdRequest *adRequest = [adapter createAdRequestWithBidResponse:adData.serverData];

    dispatch_async(dispatch_get_main_queue(), ^{
        // create banner view
        YMAAdView *adView = [[YMAAdView alloc] initWithAdUnitID:adUnitId
                                                         adSize:adSize];
        adView.delegate = adDelegate;

        // add banner ad to local variable
        self.ad = adView;

        // load ad
        [self.ad loadAdWithRequest:adRequest];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    self.ad.delegate = nil;
    self.ad = nil;
    self.yandexAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    YMABidderTokenRequestConfiguration *requestConfiguration = [[YMABidderTokenRequestConfiguration alloc] initWithAdType:YMAAdTypeBanner];

    NSDictionary *adUnitData = adData.adUnitData;
    if ([adUnitData objectForKey:bannerSizeKey]) {
        ISBannerSize *size = [adUnitData objectForKey:bannerSizeKey];
        YMABannerAdSize *adSize = [self getBannerSize:size];
        [requestConfiguration setBannerAdSize:adSize];
    }

    ISYandexAdapter *adapter = (ISYandexAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    requestConfiguration.parameters = [adapter getConfigParams];

    [adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                delegate:delegate];
}

- (YMABannerAdSize *)getBannerSize:(ISBannerSize *)size {
    YMABannerAdSize *adSize = nil;

    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:320 height:50];
    } else if ([size.sizeDescription isEqualToString:sizeLarge]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:320 height:90];
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:300 height:250];
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            adSize = [YMABannerAdSize fixedSizeWithWidth:728 height:90];
        } else {
            adSize = [YMABannerAdSize fixedSizeWithWidth:320 height:50];
        }
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:size.width height:size.height];
    }

    return adSize;
}

@end
