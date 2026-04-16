//
//  ISVerveBannerAdapter.m
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISVerveBannerAdapter.h"
#import "ISVerveBannerDelegate.h"
#import "ISVerveAdapter+Internal.h"

@interface ISVerveBannerAdapter ()

@property (nonatomic, strong) HyBidAdView *bannerAd;
@property (nonatomic, strong) ISVerveBannerDelegate *bannerAdDelegate;

@end

@implementation ISVerveBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *zoneId = [adData getString:zoneIdKey];
    LogAdapterApi_Internal(logZoneId, zoneId);

    if (!zoneId || zoneId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingZoneId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    HyBidAdSize *bannerSize = [self getBannerSize:size];

    ISVerveBannerDelegate *bannerAdDelegate = [[ISVerveBannerDelegate alloc] initWithDelegate:delegate];
    self.bannerAdDelegate = bannerAdDelegate;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAd = [[HyBidAdView alloc] initWithSize:bannerSize];
        [self.bannerAd renderAdWithContent:adData.serverData
                              withDelegate:bannerAdDelegate];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bannerAd) {
            self.bannerAd.delegate = nil;
            self.bannerAd = nil;
        }
    });

    self.bannerAdDelegate = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISVerveAdapter *adapter = (ISVerveAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Helper Methods

- (HyBidAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return HyBidAdSize.SIZE_300x250;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return HyBidAdSize.SIZE_728x90;
        } else {
            return HyBidAdSize.SIZE_320x50;
        }
    } else {
        return HyBidAdSize.SIZE_320x50;
    }
}

@end
