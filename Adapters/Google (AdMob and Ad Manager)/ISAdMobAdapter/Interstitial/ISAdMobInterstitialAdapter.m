//
//  ISAdMobInterstitialAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISAdMobInterstitialAdapter.h"
#import "ISAdMobInterstitialDelegate.h"
#import "ISAdMobAdapter+Internal.h"
#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"

@interface ISAdMobInterstitialAdapter ()

@property (nonatomic, strong) GADInterstitialAd            *interstitialAd;
@property (nonatomic, strong) ISAdMobInterstitialDelegate  *interstitialAdDelegate;
@property (nonatomic, assign) BOOL                          adAvailability;

@end

@implementation ISAdMobInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISAdMobAdapter *adapter = (ISAdMobAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    self.adAvailability = NO;

    GADInterstitialAdLoadCompletionHandler loadHandler = ^(GADInterstitialAd *_Nullable interstitialAd, NSError *_Nullable error) {
        if (error) {
            LogAdapterDelegate_Internal(logLoadFailed, networkName, error);
            ISAdapterErrorType errorType = (error.code == GADErrorNoFill) ?
                ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        if (!interstitialAd) {
            NSString *errorMessage = [NSString stringWithFormat:errorAdIsNil, adFormatInterstitial];
            LogAdapterDelegate_Internal(logError, errorMessage);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ERROR_CODE_GENERIC
                                      errorMessage:errorMessage];
            return;
        }

        self.interstitialAd = interstitialAd;
        self.adAvailability = YES;

        NSString *creativeId = interstitialAd.responseInfo.responseIdentifier;
        LogAdapterDelegate_Internal(logCreativeId, creativeId);

        if (creativeId.length) {
            NSDictionary *extraData = @{creativeIdKey: creativeId};
            [delegate adDidLoadWithExtraData:extraData];
        } else {
            [delegate adDidLoad];
        }
    };

    if (adData.serverData) {
        [GADInterstitialAd loadWithAdResponseString:adData.serverData
                                  completionHandler:loadHandler];
    } else {
        GADRequest *request = [adapter createGADRequestWithAdData:adData.adUnitData];
        [GADInterstitialAd loadWithAdUnitID:adUnitId
                                    request:request
                          completionHandler:loadHandler];
    }
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
        self.interstitialAdDelegate = [[ISAdMobInterstitialDelegate alloc] initWithDelegate:delegate];
        self.interstitialAd.fullScreenContentDelegate = self.interstitialAdDelegate;
        [self.interstitialAd presentFromRootViewController:viewController];
        self.adAvailability = NO;
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.adAvailability;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.adAvailability = NO;
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Bidding Data

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISAdMobAdapter *adapter = (ISAdMobAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    GADInterstitialSignalRequest *request = [[GADInterstitialSignalRequest alloc] initWithSignalType:requesterType];
    [adapter collectBiddingDataWithSignalRequest:request
                                          adData:adData
                                        delegate:delegate];
}

@end
