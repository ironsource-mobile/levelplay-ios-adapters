//
//  ISHyprMXBannerAdapter.m
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <HyprMX/HyprMX.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISHyprMXBannerAdapter.h"
#import "ISHyprMXBannerDelegate.h"
#import "ISHyprMXAdapter+Internal.h"
#import "ISHyprMXAdapter.h"
#import "ISHyprMXConstants.h"

@interface ISHyprMXBannerAdapter ()

@property (nonatomic, strong) HyprMXBannerView       *bannerAdView;
@property (nonatomic, strong) ISHyprMXBannerDelegate *bannerAdViewDelegate;

@end

@implementation ISHyprMXBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *propertyId = [adData getString:propertyIdKey];
    LogAdapterApi_Internal(logPropertyId, propertyId);

    if (!propertyId || propertyId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, propertyIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    if (![self isBannerSizeSupported:size]) {
        NSString *errorMessage = [NSString stringWithFormat:logUnsupportedBannerSize, size.sizeDescription];
        NSError *error = [ISError errorWithDomain:networkName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.bannerAdViewDelegate = [[ISHyprMXBannerDelegate alloc] initWithDelegate:delegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize bannerSize = [self getBannerSize:size];
        HyprMXBannerView *bannerView = [[HyprMXBannerView alloc] initWithPlacementName:propertyId
                                                                                adSize:bannerSize];
        bannerView.placementDelegate = self.bannerAdViewDelegate;
        self.bannerAdView = bannerView;

        void (^completionBlock)(BOOL) = ^(BOOL success) {
            if (success) {
                [delegate adDidLoadWithView:bannerView];
            } else {
                [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                             errorCode:ERROR_BN_LOAD_NO_FILL
                                          errorMessage:logLoadNoFill];
            }
        };

        if (adData.serverData) {
            [bannerView loadAdWithBidResponse:adData.serverData completion:completionBlock];
        } else {
            [bannerView loadAdWithCompletion:completionBlock];
        }
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView.placementDelegate = nil;
        self.bannerAdView = nil;
        self.bannerAdViewDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISHyprMXAdapter *adapter = (ISHyprMXAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    if (size == nil) {
        return NO;
    }

    if ([size.sizeDescription isEqualToString:sizeBanner] ||
        [size.sizeDescription isEqualToString:sizeRectangle] ||
        [size.sizeDescription isEqualToString:sizeSmart]) {
        return YES;
    }

    return NO;
}

- (CGSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return kHyprMXAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return kHyprMXAdSizeMediumRectangle;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return kHyprMXAdSizeLeaderBoard;
        } else {
            return kHyprMXAdSizeBanner;
        }
    }

    return kHyprMXAdSizeBanner;
}

@end
