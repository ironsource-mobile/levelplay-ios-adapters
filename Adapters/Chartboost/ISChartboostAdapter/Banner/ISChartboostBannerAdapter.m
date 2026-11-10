//
//  ISChartboostBannerAdapter.m
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISChartboostBannerAdapter.h"
#import "ISChartboostBannerDelegate.h"
#import "ISChartboostAdapter+Internal.h"

@interface ISChartboostBannerAdapter ()

@property (nonatomic, strong) CHBBanner *bannerAdView;
@property (nonatomic, strong) ISChartboostBannerDelegate *bannerAdViewDelegate;

@end

@implementation ISChartboostBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *locationId = [adData getString:locationIdKey];
    LogAdapterApi_Internal(logLocationId, locationId);

    if (!locationId || locationId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, locationIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

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

    ISChartboostAdapter *adapter = (ISChartboostAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    CHBBannerSize chartboostSize = [self getBannerSize:size];
    CHBMediation *mediation = [adapter getMediationInfo];
    NSString *serverData = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdViewDelegate = [[ISChartboostBannerDelegate alloc] initWithViewController:viewController
                                                                                     delegate:delegate];

        self.bannerAdView = [[CHBBanner alloc] initWithSize:chartboostSize
                                                   location:locationId
                                                  mediation:mediation
                                                   delegate:self.bannerAdViewDelegate];
        self.bannerAdViewDelegate.bannerView = self.bannerAdView;

        if (serverData) {
            [self.bannerAdView cacheBidResponse:serverData];
        } else {
            [self.bannerAdView cache];
        }
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView.delegate = nil;
        self.bannerAdView = nil;
        self.bannerAdViewDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISChartboostAdapter *adapter = (ISChartboostAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]     ||
        [size.sizeDescription isEqualToString:sizeLarge]      ||
        [size.sizeDescription isEqualToString:sizeRectangle]  ||
        [size.sizeDescription isEqualToString:sizeSmart]) {
        return YES;
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        return (size.height >= customBannerMinHeight && size.height <= customBannerMaxHeight);
    }

    return NO;
}

- (CHBBannerSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return CHBBannerSizeMedium;

    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? CHBBannerSizeLeaderboard : CHBBannerSizeStandard;
    }

    return CHBBannerSizeStandard;
}

@end
