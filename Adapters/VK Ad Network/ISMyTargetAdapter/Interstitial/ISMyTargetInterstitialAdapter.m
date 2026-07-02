//
//  ISMyTargetInterstitialAdapter.m
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MyTargetSDK/MyTargetSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMyTargetInterstitialAdapter.h"
#import "ISMyTargetInterstitialDelegate.h"
#import "ISMyTargetAdapter+Internal.h"
#import "ISMyTargetAdapter.h"
#import "ISMyTargetConstants.h"

@interface ISMyTargetInterstitialAdapter ()

@property (nonatomic, strong) MTRGInterstitialAd             *interstitialAd;
@property (nonatomic, strong) ISMyTargetInterstitialDelegate *interstitialAdDelegate;
@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISMyTargetInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    if (!slotId || slotId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, slotIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    self.adAvailability = NO;

    self.interstitialAdDelegate = [[ISMyTargetInterstitialDelegate alloc] initWithAdapter:self
                                                                                 delegate:delegate];

    self.interstitialAd = [MTRGInterstitialAd interstitialAdWithSlotId:slotId.integerValue];
    [self.interstitialAd.customParams setCustomParam:mediationParamValue forKey:mediationParamKey];
    [self.interstitialAd setDelegate:self.interstitialAdDelegate];
    [self.interstitialAd loadFromBid:adData.serverData];
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

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showWithController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.adAvailability;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)setInterstitialAdAvailability:(BOOL)availability {
    self.adAvailability = availability;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISMyTargetAdapter *adapter = (ISMyTargetAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
