//
//  ISSmaatoBannerAdapter.m
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISSmaatoBannerAdapter.h"
#import "ISSmaatoBannerDelegate.h"
#import "ISSmaatoAdapter+Internal.h"

@interface ISSmaatoBannerAdapter ()

@property (nonatomic, strong) SMABannerView *bannerAdView;
@property (nonatomic, strong) ISSmaatoBannerDelegate *bannerAdDelegate;

@end

@implementation ISSmaatoBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *adSpaceId = [adData getString:adSpaceIdKey];
    LogAdapterApi_Internal(logAdSpaceId, adSpaceId);

    if (!adSpaceId || adSpaceId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adSpaceIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    ISSmaatoAdapter *adapter = (ISSmaatoAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    SMABannerAdSize bannerSize = [self getBannerSize:size];
    CGRect bannerViewFrame = [self getBannerFrameForSize:size];

    self.bannerAdDelegate = [[ISSmaatoBannerDelegate alloc] initWithViewController:viewController
                                                                          delegate:delegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView = [[SMABannerView alloc] initWithFrame:bannerViewFrame];
        self.bannerAdView.autoreloadInterval = kSMABannerAutoreloadIntervalDisabled;
        self.bannerAdView.delegate = self.bannerAdDelegate;

        SMAAdRequestParams *adRequestParams = [adapter getAdRequestWithServerData:adData.serverData];

        if (adRequestParams == nil) {
            LogAdapterApi_Internal(logError, logAdRequestFailed);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ERROR_BN_LOAD_EXCEPTION
                                      errorMessage:logAdRequestFailed];
            return;
        }

        [self.bannerAdView loadWithAdSpaceId:adSpaceId
                                      adSize:bannerSize
                               requestParams:adRequestParams];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView.delegate = nil;
        self.bannerAdView = nil;
    });

    self.bannerAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISSmaatoAdapter *adapter = (ISSmaatoAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

- (SMABannerAdSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return kSMABannerAdSizeXXLarge_320x50;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return kSMABannerAdSizeMediumRectangle_300x250;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return kSMABannerAdSizeLeaderboard_728x90;
        } else {
            return kSMABannerAdSizeXXLarge_320x50;
        }
    }

    return kSMABannerAdSizeAny;
}

- (CGRect)getBannerFrameForSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return CGRectMake(0, 0, bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return CGRectMake(0, 0, rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, leaderboardWidth, leaderboardHeight);
        } else {
            return CGRectMake(0, 0, bannerWidth, bannerHeight);
        }
    }

    return CGRectZero;
}

@end
