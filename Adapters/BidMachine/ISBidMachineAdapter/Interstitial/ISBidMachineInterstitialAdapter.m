//
//  ISBidMachineInterstitialAdapter.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BidMachine/BidMachine-Swift.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISBidMachineInterstitialAdapter.h"
#import "ISBidMachineInterstitialDelegate.h"
#import "ISBidMachineAdapter+Internal.h"
#import "ISBidMachineAdapter.h"
#import "ISBidMachineConstants.h"

@interface ISBidMachineInterstitialAdapter ()

@property (nonatomic, strong) BidMachineInterstitial           *interstitialAd;
@property (nonatomic, strong) ISBidMachineInterstitialDelegate *interstitialAdDelegate;

@end

@implementation ISBidMachineInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    NSError *placementError = nil;
    BidMachinePlacement *placement = [BidMachineSdk.shared placement:BidMachineAdFormat.interstitial
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

    __weak ISBidMachineInterstitialAdapter *weakSelf = self;
    [BidMachineSdk.shared interstitialWithRequest:auctionRequest
                                       completion:^(BidMachineInterstitial * _Nullable interstitial, NSError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error || !interstitial) {
            NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
            NSString *description = error ? error.description : [NSString stringWithFormat:logLoadFailed, networkName];
            ISAdapterErrorType errorType = (code == bidMachineNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            LogInternal_Error(logError, description);
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:code
                                      errorMessage:description];
            return;
        }

        strongSelf.interstitialAdDelegate = [[ISBidMachineInterstitialDelegate alloc] initWithDelegate:delegate];
        strongSelf.interstitialAd = interstitial;

        strongSelf.interstitialAd.delegate = strongSelf.interstitialAdDelegate;
        [strongSelf.interstitialAd loadAd];
    }];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logEmptyCallback);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd.controller = viewController;
        [self.interstitialAd presentAd];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd && [self.interstitialAd canShow];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    ISBidMachineAdapter *adapter = (ISBidMachineAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithAdFormat:BidMachineAdFormat.interstitial
                              placementId:placementId
                                 delegate:delegate];
}

@end
