//
//  ISAPSInterstitialAdapter.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISAPSInterstitialAdapter.h"
#import "ISAPSInterstitialDelegate.h"
#import "ISAPSAdapter+Internal.h"

@interface ISAPSInterstitialAdapter ()

@property (nonatomic, strong) DTBAdInterstitialDispatcher *interstitialAd;
@property (nonatomic, strong) ISAPSInterstitialDelegate *interstitialAdDelegate;
@property (nonatomic, strong, nullable) DTBAdResponse *adResponse;

@end

@implementation ISAPSInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    if (!self.adResponse) {
        LogAdapterApi_Internal(logError, logAdResponseMissing);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:logAdResponseMissing];
        return;
    }

    LogAdapterApi_Internal(logUuid, self.adResponse.adSize.slotUUID);

    self.interstitialAdDelegate = [[ISAPSInterstitialDelegate alloc] initWithDelegate:delegate];

    NSDictionary *mediationHints = self.adResponse.mediationHints;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = [[DTBAdInterstitialDispatcher alloc] initWithDelegate:self.interstitialAdDelegate];
        [self.interstitialAd fetchAdWithParameters:mediationHints];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showFromController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.interstitialAd.interstitialLoaded;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = nil;
        self.interstitialAdDelegate = nil;
        self.adResponse = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *uuid = [adData getString:uuidKey];

    if (!uuid) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingConfigurationParam, uuidKey];
        LogAdapterApi_Error(logError, errorMessage);
        [delegate failureWithError:errorMessage];
        return;
    }

    ISAPSAdapter *adapter = (ISAPSAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Error(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    DTBAdSize *adSize = [self createAdSizeWithApsFormat:[adData getString:apsFormatKey] uuid:uuid adapter:adapter];

    __weak typeof(self) weakSelf = self;
    [adapter collectBiddingInfoWithSize:adSize
                               delegate:delegate
                             completion:^(DTBAdResponse *adResponse) {
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.adResponse = adResponse;
    }];
}

- (DTBAdSize *)createAdSizeWithApsFormat:(NSString *)apsFormat
                                    uuid:(NSString *)uuid
                                 adapter:(ISAPSAdapter *)adapter {
    if ([apsFormat isEqualToString:videoAdType]) {
        return [adapter createVideoAdSizeWithSlotUUID:uuid];
    }

    return [[DTBAdSize alloc] initInterstitialAdSizeWithSlotUUID:uuid];
}

@end
