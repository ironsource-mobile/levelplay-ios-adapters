//
//  ISMolocoBannerAdapter.m
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MolocoSDK/MolocoSDK-Swift.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMolocoBannerAdapter.h"
#import "ISMolocoBannerDelegate.h"
#import "ISMolocoAdapter+Internal.h"
#import "ISMolocoAdapter.h"
#import "ISMolocoConstants.h"

@interface ISMolocoBannerAdapter ()

@property (nonatomic, strong) MolocoBannerAdView           *bannerAdView;
@property (nonatomic, strong) ISMolocoBannerDelegate       *bannerAdDelegate;

@end

@implementation ISMolocoBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    // Validate adUnitId
    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    // Validate serverData
    NSString *serverData = adData.serverData;
    if (!serverData) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, serverDataKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    // Get banner size
    MolocoBannerType adSize = [self getBannerSize:size];

    // Create banner view
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create banner ad delegate
        self.bannerAdDelegate = [[ISMolocoBannerDelegate alloc] initWithDelegate:delegate];

        self.bannerAdView = [self createBannerWithAdSize:adSize
                                                 adUnitId:adUnitId
                                           viewController:viewController];
        self.bannerAdView.delegate = self.bannerAdDelegate;

        // Load ad
        [self.bannerAdView loadWithBidResponse:serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.bannerAdView destroy];
    self.bannerAdView.delegate = nil;
    self.bannerAdView = nil;
    self.bannerAdDelegate = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISMolocoAdapter *adapter = (ISMolocoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        [delegate failureWithError:error.localizedDescription];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Helper Methods

- (MolocoBannerType)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return MolocoBannerTypeRegular;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return MolocoBannerTypeMrec;
    }
    return MolocoBannerTypeRegular;
}

- (MolocoBannerAdView *)createBannerWithAdSize:(MolocoBannerType)adSize
                                      adUnitId:(NSString *)adUnitId
                                viewController:(UIViewController *)viewController {
    MolocoCreateAdParams *params = [[MolocoCreateAdParams alloc] initWithAdUnit:adUnitId
                                                                       mediation:mediationName];

    MolocoBannerAdView *bannerAdView = nil;

    if (adSize == MolocoBannerTypeMrec) {
        bannerAdView = [[Moloco shared] createMRECWithParams:params viewController:viewController];
    } else if (adSize == MolocoBannerTypeRegular) {
        bannerAdView = [[Moloco shared] createBannerWithParams:params viewController:viewController];
    }
    return bannerAdView;
}

@end
