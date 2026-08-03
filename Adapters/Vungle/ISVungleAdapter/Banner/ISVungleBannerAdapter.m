//
//  ISVungleBannerAdapter.m
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <VungleAdsSDK/VungleAdsSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISVungleBannerAdapter.h"
#import "ISVungleBannerDelegate.h"
#import "ISVungleAdapter+Internal.h"
#import "ISVungleAdapter.h"
#import "ISVungleConstants.h"

@interface ISVungleBannerAdapter ()

@property (nonatomic, strong) VungleBannerView       *bannerAd;
@property (nonatomic, strong) ISVungleBannerDelegate *bannerAdDelegate;

@end

@implementation ISVungleBannerAdapter

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

    self.bannerAdDelegate = [[ISVungleBannerDelegate alloc] initWithDelegate:delegate];

    NSString *serverData = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        VungleAdSize *adSize = [self getBannerSize:size];
        self.bannerAd = [[VungleBannerView alloc] initWithPlacementId:placementId
                                                        vungleAdSize:adSize];
        self.bannerAd.delegate = self.bannerAdDelegate;
        self.bannerAd.adapterAdFormat = adapterFormatBanner;

        if (![VungleAds isInLine:placementId] && [size.sizeDescription isEqualToString:sizeCustom]) {
            self.bannerAd.adapterAdFormat = [adapterFormatBanner stringByAppendingFormat:@"-%@", size.sizeDescription.lowercaseString];
            NSString *message = [NSString stringWithFormat:logCustomBannerSizeMismatch, (long)size.width, (long)size.height];
            [VungleMediationLogger logErrorForAd:self.bannerAd message:message];
        }

        [self.bannerAd load:serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAd.delegate = nil;
        self.bannerAd = nil;
        self.bannerAdDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISVungleAdapter *adapter = (ISVungleAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

- (VungleAdSize *)getBannerSize:(ISBannerSize *)size {
    VungleAdSize *vungleAdSize = [VungleAdSize VungleAdSizeBannerRegular];

    if ([size.sizeDescription isEqualToString:sizeCustom]) {
        vungleAdSize = [VungleAdSize VungleAdSizeFromCGSize:CGSizeMake(size.width, size.height)];
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        vungleAdSize = [VungleAdSize VungleAdSizeMREC];
    } else if ([size.sizeDescription isEqualToString:sizeLeaderboard]) {
        vungleAdSize = [VungleAdSize VungleAdSizeLeaderboard];
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice.currentDevice userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            vungleAdSize = [VungleAdSize VungleAdSizeLeaderboard];
        }
    }

    return vungleAdSize;
}

@end
