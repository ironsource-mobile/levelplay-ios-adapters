//
//  ISFacebookNativeAdAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISNativeAdProperties.h>
#import "ISFacebookNativeAdAdapter.h"
#import "ISFacebookNativeAdDelegate.h"
#import "ISFacebookAdapter+Internal.h"
#import "ISFacebookAdapter.h"
#import "ISFacebookConstants.h"

@interface ISFacebookNativeAdAdapter ()

@property (nonatomic, strong) FBNativeAd                   *nativeAd;
@property (nonatomic, strong) ISFacebookNativeAdDelegate   *nativeAdDelegate;

@end

@implementation ISFacebookNativeAdAdapter

#pragma mark - Native Ad Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                delegate:(id<ISNativeAdDelegate>)delegate {
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

    ISNativeAdProperties *nativeAdProperties = [self getNativeAdPropertiesWithAdData:adData];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.nativeAdDelegate = [[ISFacebookNativeAdDelegate alloc] initWithAdOptionsPosition:nativeAdProperties.adOptionsPosition
                                                                              viewController:viewController
                                                                                    delegate:delegate];

        self.nativeAd = [[FBNativeAd alloc] initWithPlacementID:placementId];
        self.nativeAd.delegate = self.nativeAdDelegate;

        [self.nativeAd loadAdWithBidPayload:adData.serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    [self.nativeAd unregisterView];
    self.nativeAd.delegate = nil;
    self.nativeAd = nil;
    self.nativeAdDelegate = nil;
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
