//
//  ISFacebookBannerAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISFacebookBannerAdapter.h"
#import "ISFacebookBannerDelegate.h"
#import "ISFacebookAdapter+Internal.h"
#import "ISFacebookAdapter.h"
#import "ISFacebookConstants.h"

@interface ISFacebookBannerAdapter ()

@property (nonatomic, strong) FBAdView                  *bannerAd;
@property (nonatomic, strong) ISFacebookBannerDelegate  *bannerAdDelegate;

@end

@implementation ISFacebookBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementIdKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    if (!adData.serverData) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, serverDataKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    CGRect bannerFrame = [self getBannerFrame:size];
    if (CGRectEqualToRect(bannerFrame, CGRectZero)) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:logUnsupportedBannerSize}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    FBAdSize fbSize = [self getBannerSize:size];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdDelegate = [[ISFacebookBannerDelegate alloc] initWithDelegate:delegate];

        FBAdView *banner = [[FBAdView alloc] initWithPlacementID:placementId
                                                          adSize:fbSize
                                              rootViewController:viewController];
        banner.frame = bannerFrame;
        banner.delegate = self.bannerAdDelegate;
        self.bannerAd = banner;

        [banner loadAdWithBidPayload:adData.serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAd.delegate = nil;
        [self.bannerAd removeFromSuperview];
        self.bannerAd = nil;
        self.bannerAdDelegate = nil;
    });
}

#pragma mark - Bidding Data

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISFacebookAdapter *adapter = (ISFacebookAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Helper Methods

- (FBAdSize)getBannerSize:(ISBannerSize *)size {
    FBAdSize fbSize = kFBAdSizeHeight50Banner;

    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        fbSize = kFBAdSizeHeight50Banner;
    } else if ([size.sizeDescription isEqualToString:sizeLarge]) {
        fbSize = kFBAdSizeHeight90Banner;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        fbSize = kFBAdSizeHeight250Rectangle;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        fbSize = [self isLargeScreen] ? kFBAdSizeHeight90Banner : kFBAdSizeHeight50Banner;
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        if (size.height == bannerHeight) {
            fbSize = kFBAdSizeHeight50Banner;
        } else if (size.height == largeHeight) {
            fbSize = kFBAdSizeHeight90Banner;
        } else if (size.height == rectangleHeight) {
            fbSize = kFBAdSizeHeight250Rectangle;
        }
    }

    return fbSize;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    CGRect rect = CGRectZero;

    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        rect = CGRectMake(0, 0, bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeLarge]) {
        rect = CGRectMake(0, 0, bannerWidth, largeHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        rect = CGRectMake(0, 0, rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        rect = [self isLargeScreen] ? CGRectMake(0, 0, leaderboardWidth, leaderboardHeight)
                                    : CGRectMake(0, 0, bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        if (size.height == bannerHeight) {
            rect = CGRectMake(0, 0, bannerWidth, bannerHeight);
        } else if (size.height == largeHeight) {
            rect = CGRectMake(0, 0, bannerWidth, largeHeight);
        } else if (size.height == rectangleHeight) {
            rect = CGRectMake(0, 0, rectangleWidth, rectangleHeight);
        }
    }

    return rect;
}

- (BOOL)isLargeScreen {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

@end
