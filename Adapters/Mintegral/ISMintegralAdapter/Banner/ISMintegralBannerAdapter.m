//
//  ISMintegralBannerAdapter.m
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMintegralBannerAdapter.h"
#import "ISMintegralBannerDelegate.h"
#import "ISMintegralAdapter+Internal.h"
#import "ISMintegralAdapter.h"
#import "ISMintegralConstants.h"

@interface ISMintegralBannerAdapter ()

@property (nonatomic, strong) MTGBannerAdView           *bannerAd;
@property (nonatomic, strong) ISMintegralBannerDelegate *bannerAdDelegate;

@end

@implementation ISMintegralBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    NSString *unitId = [adData getString:unitIdKey];
    LogAdapterApi_Internal(logPlacementIdAndUnitId, placementId, unitId);

    if (!unitId || unitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, unitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    self.bannerAdDelegate = [[ISMintegralBannerDelegate alloc] initWithDelegate:delegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize adSize = [self getBannerSize:size];
        self.bannerAd = [[MTGBannerAdView alloc] initBannerAdViewWithAdSize:adSize
                                                               placementId:placementId
                                                                    unitId:unitId
                                                        rootViewController:viewController];
        self.bannerAd.delegate = self.bannerAdDelegate;
        self.bannerAd.autoRefreshTime = 0;
        self.bannerAd.showCloseButton = NO;
        LogAdapterApi_Internal(logLoadBanner, (int)adSize.width, (int)adSize.height, placementId, unitId);
        [self.bannerAd loadBannerAdWithBidToken:adData.serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bannerAd destroyBannerAdView];
        self.bannerAd = nil;
        self.bannerAdDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    NSString *unitId = [adData getString:unitIdKey];

    ISMintegralAdapter *adapter = (ISMintegralAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithPlacementId:placementId
                                        unitId:unitId
                                        adType:MintegralBannerAd
                                      delegate:delegate];
}

- (CGSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return [MTGAdSize getSizeBySizeType:MTGStandardBannerType320x50];
    } else if ([size.sizeDescription isEqualToString:sizeLarge]) {
        return [MTGAdSize getSizeBySizeType:MTGLargeBannerType320x90];
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return [MTGAdSize getSizeBySizeType:MTGMediumRectangularBanner300x250];
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGSizeMake(leaderboardWidth, leaderboardHeight);
        } else {
            return [MTGAdSize getSizeBySizeType:MTGStandardBannerType320x50];
        }
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        return CGSizeMake(size.width, size.height);
    }

    return [MTGAdSize getSizeBySizeType:MTGStandardBannerType320x50];
}

@end
