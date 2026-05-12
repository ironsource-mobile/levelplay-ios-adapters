//
//  ISPangleBannerAdapter.m
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISPangleBannerAdapter.h"
#import "ISPangleBannerDelegate.h"
#import "ISPangleAdapter+Internal.h"
#import "ISPangleAdapter.h"
#import "ISPangleConstants.h"

@interface ISPangleBannerAdapter ()

@property (nonatomic, strong) PAGBannerAd           *bannerAdView;
@property (nonatomic, strong) ISPangleBannerDelegate *bannerAdDelegate;

@end

@implementation ISPangleBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    // validate slotId
    if (!slotId || slotId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingSlotId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISPangleAdapter *adapter = (ISPangleAdapter *)[self getNetworkAdapter];
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

    if ([adapter isCoppaChildUser]) {
        NSError *error = [adapter childError];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.description];
        return;
    }
    
    PAGBannerAdSize bannerAdSize = [self getBannerSize:size];

    self.bannerAdDelegate = [[ISPangleBannerDelegate alloc] initWithDelegate:delegate];

    PAGBannerRequest *request = [PAGBannerRequest requestWithBannerSize:bannerAdSize];
    request.adString = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        __weak ISPangleBannerAdapter *weakSelf = self;
        [PAGBannerAd loadAdWithSlotID:slotId
                              request:request
                    completionHandler:^(PAGBannerAd * _Nullable bannerAd, NSError * _Nullable error) {
            __typeof__(self) strongSelf = weakSelf;
            if (error || !bannerAd) {
                NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
                NSString *description = error ? error.description : [NSString stringWithFormat:logLoadFailed, networkName];
                ISAdapterErrorType errorType = (code == pangleNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
                LogInternal_Error(logError, description);
                [delegate adDidFailToLoadWithErrorType:errorType
                                             errorCode:code
                                          errorMessage:description];
                return;
            }

            bannerAd.delegate = strongSelf.bannerAdDelegate;
            bannerAd.rootViewController = viewController;

            CGRect bannerFrame = [strongSelf getBannerFrame:size];
            bannerAd.bannerView.frame = bannerFrame;

            strongSelf.bannerAdView = bannerAd;

            [delegate adDidLoadWithView:bannerAd.bannerView];
        }];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.bannerAdView.rootViewController = nil;
    self.bannerAdView.delegate = nil;
    self.bannerAdView = nil;
    self.bannerAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    ISPangleAdapter *adapter = (ISPangleAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithSlotId:slotId
                                 delegate:delegate];
}

- (PAGBannerAdSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return kPAGBannerSize320x50;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return kPAGBannerSize300x250;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return kPAGBannerSize728x90;
        }
    }

    return kPAGBannerSize320x50;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    CGRect rect = CGRectZero;

    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        rect = CGRectMake(0, 0, bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        rect = CGRectMake(0, 0, rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            rect = CGRectMake(0, 0, leaderboardWidth, leaderboardHeight);
        } else {
            rect = CGRectMake(0, 0, bannerWidth, bannerHeight);
        }
    }

    return rect;
}

@end
