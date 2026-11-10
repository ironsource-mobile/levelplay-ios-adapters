//
//  ISOguryInterstitialAdapter.m
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISOguryInterstitialAdapter.h"
#import "ISOguryInterstitialDelegate.h"
#import "ISOguryAdapter+Internal.h"
#import "ISOguryAdapter.h"
#import "ISOguryConstants.h"

@interface ISOguryInterstitialAdapter ()

@property (nonatomic, strong) OguryInterstitialAd          *interstitialAd;
@property (nonatomic, strong) ISOguryInterstitialDelegate  *interstitialAdDelegate;

@end

@implementation ISOguryInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    self.interstitialAdDelegate = [[ISOguryInterstitialDelegate alloc] initWithDelegate:delegate];

    OguryMediation *mediation = [[OguryMediation alloc] initWithName:mediationName
                                                            version:[LevelPlay sdkVersion]
                                                     adapterVersion:OguryAdapterVersion];
    self.interstitialAd = [[OguryInterstitialAd alloc] initWithAdUnitId:adUnitId
                                                              mediation:mediation];
    self.interstitialAd.delegate = self.interstitialAdDelegate;
    [self.interstitialAd loadWithAdMarkup:adData.serverData];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:logShowFailed}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    [self.interstitialAd showAdInViewController:viewController];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && [self.interstitialAd isLoaded];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISOguryAdapter *adapter = (ISOguryAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
