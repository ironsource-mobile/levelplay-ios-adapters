//
//  ISAdMobNativeAdAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISNativeAdProperties.h>
#import "ISAdMobNativeAdAdapter.h"
#import "ISAdMobNativeAdDelegate.h"
#import "ISAdMobAdapter+Internal.h"
#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"

@interface ISAdMobNativeAdAdapter ()

// You must keep a strong reference to the GADAdLoader during the ad loading process.
@property (nonatomic, strong) GADAdLoader                *nativeAdLoader;
@property (nonatomic, strong) ISAdMobNativeAdDelegate    *nativeAdDelegate;

@end

@implementation ISAdMobNativeAdAdapter

#pragma mark - Native Ad Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                delegate:(id<ISNativeAdDelegate>)delegate {
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

    ISNativeAdProperties *nativeAdProperties = [self getNativeAdPropertiesWithAdData:adData];
    ISAdMobAdapter *adapter = (ISAdMobAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        GADNativeAdViewAdOptions *nativeAdViewOptions = [[GADNativeAdViewAdOptions alloc] init];
        nativeAdViewOptions.preferredAdChoicesPosition = [self getAdChoicesPosition:nativeAdProperties.adOptionsPosition];

        self.nativeAdLoader = [[GADAdLoader alloc] initWithAdUnitID:adUnitId
                                                rootViewController:viewController
                                                           adTypes:@[GADAdLoaderAdTypeNative]
                                                           options:@[nativeAdViewOptions]];

        self.nativeAdDelegate = [[ISAdMobNativeAdDelegate alloc] initWithViewController:viewController
                                                                              delegate:delegate];
        self.nativeAdLoader.delegate = self.nativeAdDelegate;

        if (adData.serverData) {
            [self.nativeAdLoader loadWithAdResponseString:adData.serverData];
        } else {
            GADRequest *request = [adapter createGADRequestWithAdData:adData.adUnitData];
            [self.nativeAdLoader loadRequest:request];
        }
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.nativeAdLoader.delegate = nil;
    self.nativeAdLoader = nil;
    self.nativeAdDelegate = nil;
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

    ISNativeAdProperties *nativeAdProperties = [self getNativeAdPropertiesWithAdData:adData];

    GADNativeSignalRequest *request = [[GADNativeSignalRequest alloc] initWithSignalType:requesterType];
    request.preferredAdChoicesPosition = [self getAdChoicesPosition:nativeAdProperties.adOptionsPosition];
    request.adLoaderAdTypes = [NSSet setWithObject:GADAdLoaderAdTypeNative];
    request.shouldRequestMultipleImages = YES;

    [adapter collectBiddingDataWithSignalRequest:request
                                          adData:adData
                                        delegate:delegate];
}

#pragma mark - Helper Methods

- (GADAdChoicesPosition)getAdChoicesPosition:(ISAdOptionsPosition)adOptionsPosition {
    switch (adOptionsPosition) {
        case ISAdOptionsPositionTopLeft:
            return GADAdChoicesPositionTopLeftCorner;
        case ISAdOptionsPositionTopRight:
            return GADAdChoicesPositionTopRightCorner;
        case ISAdOptionsPositionBottomLeft:
            return GADAdChoicesPositionBottomLeftCorner;
        case ISAdOptionsPositionBottomRight:
            return GADAdChoicesPositionBottomRightCorner;
    }

    return GADAdChoicesPositionBottomLeftCorner;
}

@end
