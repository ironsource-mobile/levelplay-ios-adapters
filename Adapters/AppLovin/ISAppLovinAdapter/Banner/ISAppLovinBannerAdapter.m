//
//  ISAppLovinBannerAdapter.m
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISAppLovinBannerAdapter.h"
#import "ISAppLovinBannerDelegate.h"
#import "ISAppLovinAdapter+Internal.h"

@interface ISAppLovinBannerAdapter ()

@property (nonatomic, strong) ALAdView *bannerAd;
@property (nonatomic, strong) ISAppLovinBannerDelegate *bannerAdDelegate;

@end

@implementation ISAppLovinBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *zoneId = [adData getString:zoneIdKey];
    LogAdapterApi_Internal(logZoneId, zoneId);

    if (!zoneId || zoneId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, zoneIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        ALAdSize *appLovinSize = [self getBannerSize:size];

        if (appLovinSize == nil) {
            NSError *error = [NSError errorWithDomain:networkName
                                                 code:ERROR_BN_UNSUPPORTED_SIZE
                                             userInfo:@{NSLocalizedDescriptionKey:logUnsupportedBannerSize}];
            LogAdapterApi_Internal(logError, error);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        self.bannerAd = [[ALAdView alloc] initWithSize:appLovinSize];
        self.bannerAd.frame = [self getBannerFrame:size];

        self.bannerAdDelegate = [[ISAppLovinBannerDelegate alloc] initWithBannerView:self.bannerAd
                                                                            delegate:delegate];

        self.bannerAd.adLoadDelegate = self.bannerAdDelegate;
        self.bannerAd.adDisplayDelegate = self.bannerAdDelegate;
        self.bannerAd.adEventDelegate = self.bannerAdDelegate;

        [ALSdk.shared.adService loadNextAdForZoneIdentifier:zoneId
                                                  andNotify:self.bannerAdDelegate];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAd.adLoadDelegate = nil;
        self.bannerAd.adDisplayDelegate = nil;
        self.bannerAd.adEventDelegate = nil;
        self.bannerAd = nil;
    });

    self.bannerAdDelegate = nil;
}

#pragma mark - Helper Methods

- (ALAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner] ||
        [size.sizeDescription isEqualToString:sizeLarge]) {
        return ALAdSize.banner;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return ALAdSize.mrec;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return ALAdSize.leader;
        } else {
            return ALAdSize.banner;
        }
    } else if (size.height >= customBannerMinHeight && size.height <= customBannerMaxHeight) {
        return ALAdSize.banner;
    }

    return nil;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner] ||
        [size.sizeDescription isEqualToString:sizeLarge]) {
        return CGRectMake(0, 0, bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return CGRectMake(0, 0, rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, largeWidth, largeHeight);
        } else {
            return CGRectMake(0, 0, bannerWidth, bannerHeight);
        }
    } else if (size.height >= customBannerMinHeight && size.height <= customBannerMaxHeight) {
        return CGRectMake(0, 0, bannerWidth, bannerHeight);
    }

    return CGRectZero;
}

@end
