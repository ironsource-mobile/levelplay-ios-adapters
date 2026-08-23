//
//  ISPubMaticBannerAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import "ISPubMaticBannerAdapter.h"
#import "ISPubMaticBannerDelegate.h"
#import "ISPubMaticAdapter+Internal.h"

@interface ISPubMaticBannerAdapter ()

@property (nonatomic, strong) POBBannerView *bannerAdView;
@property (nonatomic, strong) ISPubMaticBannerDelegate *bannerAdDelegate;

@end

@implementation ISPubMaticBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    NSString *serverData = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdDelegate = [[ISPubMaticBannerDelegate alloc] initWithViewController:viewController
                                                                                    delegate:delegate];
        self.bannerAdView = [[POBBannerView alloc] init];
        self.bannerAdView.delegate = self.bannerAdDelegate;
        [self.bannerAdView loadAdWithResponse:serverData forBiddingHost:POBSDKBiddingHostUnityLevelPlay];
        [self.bannerAdView pauseAutoRefresh];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView.delegate = nil;
        self.bannerAdView = nil;
        self.bannerAdDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISPubMaticAdapter *adapter = (ISPubMaticAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    NSDictionary *adUnitData = [adData getAdUnitData];
    ISBannerSize *size = [adUnitData objectForKey:bannerSizeKey];

    if (!size) {
        LogAdapterApi_Internal(logError, logUnsupportedBannerSize);
        [delegate failureWithError:logUnsupportedBannerSize];
        return;
    }

    POBAdFormat bannerFormat = [self getBannerFormat:size];

    dispatch_async(dispatch_get_main_queue(), ^{
        [adapter collectBiddingDataWithDelegate:delegate
                                       adFormat:bannerFormat];
    });
}

- (POBAdFormat)getBannerFormat:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return POBAdFormatMREC;
    }

    return POBAdFormatBanner;
}

@end
