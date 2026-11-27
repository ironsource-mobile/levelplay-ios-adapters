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

    __weak ISBidMachineInterstitialAdapter *weakSelf = self;
    void (^completion)(BidMachineInterstitial * _Nullable, BidMachineError * _Nullable) = ^(BidMachineInterstitial * _Nullable interstitial, BidMachineError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error || !interstitial) {
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

        strongSelf.interstitialAdDelegate = [[ISBidMachineInterstitialDelegate alloc] initWithAdapter:strongSelf
                                                                                             delegate:delegate];
        strongSelf.interstitialAd = interstitial;
        strongSelf.interstitialAd.delegate = strongSelf.interstitialAdDelegate;

        NSString *creativeId = interstitial.auctionInfo.creativeId;
        LogAdapterDelegate_Internal(logCreativeId, creativeId);
        if (creativeId.length) {
            NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
            [delegate adDidLoadWithExtraData:extraData];
        } else {
            [delegate adDidLoad];
        }
    };

    BidMachineInstance *instance = ISBidMachineAdapter.bidMachineInstance;
    if (adData.serverData.length > 0) {
        [instance loadInterstitialWithPayload:adData.serverData
                                   completion:completion];
    } else {
        BidMachinePlacement *placement = nil;
        if (placementId.length > 0) {
            placement = [[BidMachinePlacement alloc] initWithId:placementId extras:@{}];
        }
        [instance loadInterstitialWithPlacement:placement
                                     completion:completion];
    }
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logEmptyCallback);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isAdAvailableWithAdData:adData]) {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                      withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
            LogAdapterApi_Internal(logError, error);
            [delegate adDidFailToShowWithErrorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        [self.interstitialAd showFrom:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd && [self.interstitialAd canShow];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logEmptyCallback);
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)releaseAd {
    self.interstitialAd = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    ISBidMachineAdapter *adapter = (ISBidMachineAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithPlacementId:placementId
                                      delegate:delegate];
}

@end
