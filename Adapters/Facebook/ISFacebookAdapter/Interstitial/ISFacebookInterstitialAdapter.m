//
//  ISFacebookInterstitialAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISFacebookInterstitialAdapter.h"
#import "ISFacebookInterstitialDelegate.h"
#import "ISFacebookAdapter+Internal.h"
#import "ISFacebookAdapter.h"
#import "ISFacebookConstants.h"

@interface ISFacebookInterstitialAdapter ()

@property (nonatomic, strong) FBInterstitialAd                *interstitialAd;
@property (nonatomic, strong) ISFacebookInterstitialDelegate  *interstitialAdDelegate;

@end

@implementation ISFacebookInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

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

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAdDelegate = [[ISFacebookInterstitialDelegate alloc] initWithDelegate:delegate];

        self.interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementId];
        self.interstitialAd.delegate = self.interstitialAdDelegate;

        [self.interstitialAd loadAdWithBidPayload:adData.serverData];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSString *errorMessage = [NSString stringWithFormat:errorShowFailed, networkName];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.interstitialAd showAdFromRootViewController:viewController]) {
            NSString *errorMessage = [NSString stringWithFormat:errorShowFailed, networkName];
            NSError *error = [NSError errorWithDomain:networkName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
            LogAdapterApi_Internal(logError, error);
            [delegate adDidFailToShowWithErrorCode:error.code
                                      errorMessage:error.localizedDescription];
        }
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.interstitialAd.isAdValid;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Bidding Data

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISFacebookAdapter *adapter = (ISFacebookAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
