//
//  ISBidMachineBannerAdapter.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
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

    BidMachineAdFormat *bannerFormat = [self getBannerFormat:size];
    if (bannerFormat == nil) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:logUnsupportedBannerSize}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    NSError *placementError = nil;
    BidMachinePlacement *placement = [BidMachineSdk.shared placement:bannerFormat
                                                               error:&placementError
                                                             builder:^(id<BidMachinePlacementBuilderProtocol> builder) {
        if (placementId.length > 0) {
            [builder withPlacementId:placementId];
        }
    }];

    if (!placement || placementError) {
        LogInternal_Error(logError, placementError.description);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:placementError.code
                                  errorMessage:placementError.description];
        return;
    }

    BidMachineAuctionRequest *auctionRequest = [BidMachineSdk.shared auctionRequestWithPlacement:placement
                                                                                         builder:^(id<BidMachineAuctionRequestBuilderProtocol> builder) {
        [builder withPayload:adData.serverData];
    }];

    __weak ISBidMachineBannerAdapter *weakSelf = self;
    [BidMachineSdk.shared bannerWithRequest:auctionRequest
                                 completion:^(BidMachineBanner * _Nullable banner, NSError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error || !banner) {
            NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
            NSString *description = error ? error.description : [NSString stringWithFormat:logLoadFailed, networkName];
            ISAdapterErrorType errorType = (code == bidMachineNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            LogInternal_Error(logError, description);
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:code
                                      errorMessage:description];
            return;
        }

        strongSelf.bannerAdDelegate = [[ISBidMachineBannerDelegate alloc] initWithBanner:banner
                                                                                 delegate:delegate];
        strongSelf.bannerAdView = banner;

        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.bannerAdView.controller = viewController;
            strongSelf.bannerAdView.delegate = strongSelf.bannerAdDelegate;
            [strongSelf.bannerAdView loadAd];
        });
    }];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logEmptyCallback);

    self.bannerAdView.controller = nil;
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
        BidMachineAdFormat *bannerFormat = [self getBannerFormat:size];

        if (bannerFormat == nil) {
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

        [adapter collectBiddingDataWithAdFormat:bannerFormat
                                  placementId:placementId
                                     delegate:delegate];
    } else {
        LogAdapterApi_Internal(logTokenFailed);
        [delegate failureWithError:logTokenFailed];
    }
}

- (BidMachineAdFormat *)getBannerFormat:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return BidMachineAdFormat.banner320x50;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return BidMachineAdFormat.banner300x250;
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return BidMachineAdFormat.banner728x90;
        } else {
            return BidMachineAdFormat.banner320x50;
        }
    }
    return nil;
}

@end
