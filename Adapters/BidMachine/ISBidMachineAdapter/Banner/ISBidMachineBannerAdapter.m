//
//  ISBidMachineBannerAdapter.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/LPMAdSize.h>
#import "ISBidMachineBannerAdapter.h"
#import "ISBidMachineBannerDelegate.h"
#import "ISBidMachineAdapter+Internal.h"
#import "ISBidMachineAdapter.h"
#import "ISBidMachineConstants.h"

@interface ISBidMachineBannerAdapter ()

@property (nonatomic, strong) BidMachineBanner           *bannerAdView;
@property (nonatomic, strong) ISBidMachineBannerDelegate *bannerAdDelegate;

@end

@implementation ISBidMachineBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    BidMachineBannerSize *bannerSize = [self getBannerSize:size];
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

    __weak ISBidMachineBannerAdapter *weakSelf = self;
    void (^completion)(BidMachineBanner * _Nullable, BidMachineError * _Nullable) = ^(BidMachineBanner * _Nullable banner, BidMachineError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error || !banner) {
            NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
            NSString *description = error ? error.description : [NSString stringWithFormat:logLoadFailed, networkName];
            ISAdapterErrorType errorType = (code == BidMachineErrorCodeNoContent) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            LogInternal_Error(logError, description);
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:code
                                      errorMessage:description];
            return;
        }

        if (!strongSelf) {
            LogInternal_Error(logError, logAdapterNil);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ISAdapterErrorInternal
                                      errorMessage:logAdapterNil];
            return;
        }

        strongSelf.bannerAdDelegate = [[ISBidMachineBannerDelegate alloc] initWithBanner:banner
                                                                                 delegate:delegate];
        strongSelf.bannerAdView = banner;
        strongSelf.bannerAdView.rootViewController = viewController;
        strongSelf.bannerAdView.delegate = strongSelf.bannerAdDelegate;

        CGSize bannerViewSize = bannerSize.cgSize;
        if (bannerViewSize.height <= 0) {
            bannerViewSize = banner.adSize.cgSize;
        }
        banner.frame = CGRectMake(0, 0, bannerViewSize.width, bannerViewSize.height);

        NSString *creativeId = banner.auctionInfo.creativeId;
        LogAdapterDelegate_Internal(logCreativeId, creativeId);
        if (creativeId.length) {
            NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
            [delegate adDidLoadWithView:banner
                              extraData:extraData];
        } else {
            [delegate adDidLoadWithView:banner];
        }
    };

    BidMachineInstance *instance = ISBidMachineAdapter.bidMachineInstance;
    if (adData.serverData.length > 0) {
        [instance loadBannerWithPayload:adData.serverData
                                   size:bannerSize
                             completion:completion];
    } else {
        BidMachinePlacement *placement = nil;
        if (placementId.length > 0) {
            placement = [[BidMachinePlacement alloc] initWithId:placementId extras:@{}];
        }
        [instance loadBannerWithPlacement:placement
                                     size:bannerSize
                               completion:completion];
    }
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logEmptyCallback);

    self.bannerAdView.rootViewController = nil;
    self.bannerAdView.delegate = nil;
    self.bannerAdView = nil;
    self.bannerAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    NSDictionary *adUnitData = adData.adUnitData;

    if ([adUnitData objectForKey:bannerSizeKey]) {
        ISBannerSize *size = [adUnitData objectForKey:bannerSizeKey];
        BidMachineBannerSize *bannerSize = [self getBannerSize:size];

        if (bannerSize == nil) {
            LogAdapterApi_Internal(logTokenFailed);
            [delegate failureWithError:logTokenFailed];
            return;
        }

        ISBidMachineAdapter *adapter = (ISBidMachineAdapter *)[self getNetworkAdapter];

        if (!adapter) {
            LogAdapterApi_Internal(logAdapterNil);
            [delegate failureWithError:logAdapterNil];
            return;
        }

        [adapter collectBiddingDataWithPlacementId:placementId
                                          delegate:delegate];
    } else {
        LogAdapterApi_Internal(logTokenFailed);
        [delegate failureWithError:logTokenFailed];
    }
}

- (BidMachineBannerSize *)getBannerSize:(ISBannerSize *)size {
    BidMachineBannerSize *bannerSize = nil;

    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        bannerSize = BidMachineBannerSize.banner;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        bannerSize = BidMachineBannerSize.mrec;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            bannerSize = BidMachineBannerSize.leaderboard;
        } else {
            bannerSize = BidMachineBannerSize.banner;
        }
    }

    if (size.isAdaptive) {
        LPMAdSize *adaptiveSize = [size toLPMAdSize];
        if (adaptiveSize.width > 0) {
            bannerSize = [BidMachineBannerSize adaptiveWithWidth:(uint32_t)adaptiveSize.width
                                                       maxHeight:0];
        }
    }

    return bannerSize;
}

@end
