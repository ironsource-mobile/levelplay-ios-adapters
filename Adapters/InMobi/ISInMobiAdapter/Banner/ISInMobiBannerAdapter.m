//
//  ISInMobiBannerAdapter.m
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <InMobiSDK/InMobiSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISInMobiBannerAdapter.h"
#import "ISInMobiBannerDelegate.h"
#import "ISInMobiAdapter+Internal.h"
#import "ISInMobiAdapter.h"
#import "ISInMobiConstants.h"

@interface ISInMobiBannerAdapter ()

@property (nonatomic, strong) IMBanner *bannerAd;
@property (nonatomic, strong) ISInMobiBannerDelegate *bannerAdDelegate;

@end

@implementation ISInMobiBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    // Validate placementId
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

    // Validate serverData
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

    // Check if banner size is supported
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

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdDelegate = [[ISInMobiBannerDelegate alloc] initWithDelegate:delegate];

        self.bannerAd = [self getInMobiBanner:self.bannerAdDelegate
                                         size:size
                                  placementId:placementId];

        // Disable auto refresh
        [self.bannerAd shouldAutoRefresh:NO];

        // Load ad with bidding response
        NSData *data = [adData.serverData dataUsingEncoding:NSUTF8StringEncoding];
        [self.bannerAd load:data];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bannerAd != nil) {
            [self.bannerAd removeFromSuperview];
            self.bannerAd.delegate = nil;
            self.bannerAd = nil;
        }

        self.bannerAdDelegate = nil;
    });
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISInMobiAdapter *adapter = (ISInMobiAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Helper Methods

- (IMBanner *)getInMobiBanner:(id<IMBannerDelegate>)delegate
                         size:(ISBannerSize *)size
                  placementId:(NSString *)placementId {
    IMBanner *inMobiBanner = nil;
    CGRect frame = CGRectZero;

    if ([size.sizeDescription isEqualToString:sizeBanner] ||
        [size.sizeDescription isEqualToString:sizeLarge]) {
        frame = CGRectMake(0, 0, bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        frame = CGRectMake(0, 0, rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            frame = CGRectMake(0, 0, largeWidth, largeHeight);
        } else {
            frame = CGRectMake(0, 0, bannerWidth, bannerHeight);
        }
    } else if ([size.sizeDescription isEqualToString:sizeCustom]) {
        frame = CGRectMake(0, 0, size.width, size.height);
    }

    if (!CGRectIsEmpty(frame)) {
        inMobiBanner = [[IMBanner alloc] initWithFrame:frame
                                           placementId:[placementId longLongValue]
                                              delegate:delegate];
    }

    return inMobiBanner;
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    return ([size.sizeDescription isEqualToString:sizeBanner] ||
            [size.sizeDescription isEqualToString:sizeLarge] ||
            [size.sizeDescription isEqualToString:sizeRectangle] ||
            [size.sizeDescription isEqualToString:sizeSmart] ||
            [size.sizeDescription isEqualToString:sizeCustom]);
}

@end
