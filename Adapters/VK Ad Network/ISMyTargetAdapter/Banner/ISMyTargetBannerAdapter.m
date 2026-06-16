//
//  ISMyTargetBannerAdapter.m
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MyTargetSDK/MyTargetSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMyTargetBannerAdapter.h"
#import "ISMyTargetBannerDelegate.h"
#import "ISMyTargetAdapter+Internal.h"
#import "ISMyTargetAdapter.h"
#import "ISMyTargetConstants.h"

@interface ISMyTargetBannerAdapter ()

@property (nonatomic, strong) MTRGAdView               *bannerAdView;
@property (nonatomic, strong) ISMyTargetBannerDelegate *bannerAdViewDelegate;

@end

@implementation ISMyTargetBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    if (!slotId || slotId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, slotIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    MTRGAdSize *bannerSize = [self getBannerSize:size];
    if (bannerSize == nil) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:logUnsupportedBannerSize}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.bannerAdViewDelegate = [[ISMyTargetBannerDelegate alloc] initWithDelegate:delegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView = [MTRGAdView adViewWithSlotId:slotId.integerValue];
        self.bannerAdView.adSize = bannerSize;
        [self.bannerAdView.customParams setCustomParam:mediationParamValue forKey:mediationParamKey];
        self.bannerAdView.viewController = viewController;
        self.bannerAdView.frame = CGRectMake(0, 0, size.width, size.height);
        [self.bannerAdView setDelegate:self.bannerAdViewDelegate];
        LogAdapterApi_Internal(logLoadBanner, (int)size.width, (int)size.height, slotId);
        [self.bannerAdView loadFromBid:adData.serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView.delegate = nil;
        self.bannerAdView.viewController = nil;
        self.bannerAdView = nil;
        self.bannerAdViewDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISMyTargetAdapter *adapter = (ISMyTargetAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

- (MTRGAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return MTRGAdSize.adSize320x50;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return MTRGAdSize.adSize300x250;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return MTRGAdSize.adSize728x90;
        } else {
            return MTRGAdSize.adSize320x50;
        }
    }
    return nil;
}

@end
