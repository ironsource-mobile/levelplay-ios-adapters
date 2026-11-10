//
//  ISBigoBannerAdapter.m
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BigoADS/BigoAdSdk.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISBigoBannerAdapter.h"
#import "ISBigoBannerDelegate.h"
#import "ISBigoAdapter+Internal.h"
#import "ISBigoAdapter.h"
#import "ISBigoConstants.h"

@interface ISBigoBannerAdapter ()

@property (nonatomic, strong) BigoBannerAd           *bannerAd;
@property (nonatomic, strong) BigoBannerAdLoader     *bannerAdLoader;
@property (nonatomic, strong) ISBigoBannerDelegate   *bannerAdDelegate;

@end

@implementation ISBigoBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

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

    BigoAdSize *adSize = [self getBannerSize:size];

    if (adSize == nil) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:logUnsupportedBannerSize}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISBigoAdapter *adapter = (ISBigoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:logAdapterNil];
        return;
    }

    self.bannerAdDelegate = [[ISBigoBannerDelegate alloc] initWithAdapter:self
                                                                delegate:delegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        BigoBannerAdRequest *request = [[BigoBannerAdRequest alloc] initWithSlotId:slotId
                                                                           adSizes:@[adSize]];
        [request setServerBidPayload:adData.serverData];

        self.bannerAdLoader = [[BigoBannerAdLoader alloc] initWithBannerAdLoaderDelegate:self.bannerAdDelegate];
        self.bannerAdLoader.ext = [adapter getMediationInfo];
        [self.bannerAdLoader loadAd:request];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bannerAd destroy];
        self.bannerAd = nil;
    });
    self.bannerAdDelegate = nil;
    self.bannerAdLoader = nil;
}

- (void)storeBannerAd:(BigoBannerAd *)ad {
    self.bannerAd = ad;
    [self.bannerAd setAdInteractionDelegate:self.bannerAdDelegate];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISBigoAdapter *adapter = (ISBigoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

- (BigoAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return BigoAdSize.BANNER;
    }
    if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return BigoAdSize.MEDIUM_RECTANGLE;
    }
    if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return BigoAdSize.LARGE_BANNER;
        } else {
            return BigoAdSize.BANNER;
        }
    }

    return nil;
}

@end
