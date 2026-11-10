//
//  ISInMobiInterstitialAdapter.m
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <InMobiSDK/InMobiSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISInMobiInterstitialAdapter.h"
#import "ISInMobiInterstitialDelegate.h"
#import "ISInMobiAdapter+Internal.h"
#import "ISInMobiAdapter.h"
#import "ISInMobiConstants.h"

@interface ISInMobiInterstitialAdapter ()

@property (nonatomic, strong) IMInterstitial *interstitialAd;
@property (nonatomic, strong) ISInMobiInterstitialDelegate *interstitialAdDelegate;

@end

@implementation ISInMobiInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
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

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAdDelegate = [[ISInMobiInterstitialDelegate alloc] initWithDelegate:delegate];

        self.interstitialAd = [[IMInterstitial alloc] initWithPlacementId:[placementId longLongValue]
                                                                  delegate:self.interstitialAdDelegate];

        // Load ad with bidding response
        NSData *data = [adData.serverData dataUsingEncoding:NSUTF8StringEncoding];
        [self.interstitialAd load:data];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:logAdNotReady, @"Interstitial"]}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showFrom:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && [self.interstitialAd isReady];
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

@end
