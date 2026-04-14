//
//  ISMobileFuseBannerAdapter.m
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MobileFuseSDK/MFBannerAd.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMobileFuseBannerAdapter.h"
#import "ISMobileFuseBannerDelegate.h"
#import "ISMobileFuseAdapter+Internal.h"
#import "ISMobileFuseConstants.h"

@interface ISMobileFuseBannerAdapter ()

@property (nonatomic, strong) MFAd *ad;
@property (nonatomic, strong) ISMobileFuseBannerDelegate *mobileFuseAdDelegate;

@end

@implementation ISMobileFuseBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {

    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingPlacementId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    // get size
    MFBannerAdSize bannerSize = [self getBannerSize:size];

    if (bannerSize == MOBILEFUSE_BANNER_SIZE_DEFAULT) {
        NSError *error = [ISError createErrorWithDomain:networkName
                                                   code:ERROR_BN_UNSUPPORTED_SIZE
                                                message:logUnsupportedBannerSize];
        LogAdapterApi_Internal(logError, error.description);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    // create banner ad delegate
    ISMobileFuseBannerDelegate *bannerAdDelegate = [[ISMobileFuseBannerDelegate alloc] initWithDelegate:delegate];
    self.mobileFuseAdDelegate = bannerAdDelegate;

    // create banner view
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = [[MFBannerAd alloc] initWithPlacementId:placementId
                                                 withSize:bannerSize];

        [self.ad registerAdCallbackReceiver:self.mobileFuseAdDelegate];
        [self.ad setMuted:YES]; // banner ads should be muted

        [self.ad loadAdWithBiddingResponseToken:adData.serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad destroy];
        self.ad = nil;
    });
    self.mobileFuseAdDelegate = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISMobileFuseAdapter *adapter = (ISMobileFuseAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Helper Methods

- (MFBannerAdSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return MOBILEFUSE_BANNER_SIZE_320x50;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return MOBILEFUSE_BANNER_SIZE_300x250;
    } else if ([size.sizeDescription isEqualToString:sizeLeaderboard]) {
        return MOBILEFUSE_BANNER_SIZE_728x90;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return MOBILEFUSE_BANNER_SIZE_728x90;
        } else {
            return MOBILEFUSE_BANNER_SIZE_320x50;
        }
    }
    return MOBILEFUSE_BANNER_SIZE_DEFAULT;
}

@end
