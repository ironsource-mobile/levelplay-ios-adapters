//
//  ISMobileFuseRewardedAdapter.m
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MobileFuseSDK/MFRewardedAd.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMobileFuseRewardedAdapter.h"
#import "ISMobileFuseRewardedDelegate.h"
#import "ISMobileFuseAdapter+Internal.h"
#import "ISMobileFuseConstants.h"

@interface ISMobileFuseRewardedAdapter ()

@property (nonatomic, strong) MFAd *ad;
@property (nonatomic, strong) ISMobileFuseRewardedDelegate *mobileFuseAdDelegate;

@end

@implementation ISMobileFuseRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingPlacementId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    // create rewarded ad delegate
    ISMobileFuseRewardedDelegate *adDelegate = [[ISMobileFuseRewardedDelegate alloc] initWithDelegate:delegate];
    self.mobileFuseAdDelegate = adDelegate;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = [[MFRewardedAd alloc] initWithPlacementId:placementId];
        [self.ad registerAdCallbackReceiver:self.mobileFuseAdDelegate];
        // load ad
        [self.ad loadAdWithBiddingResponseToken:adData.serverData];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logNoAdsToShow, networkName]];
        LogAdapterApi_Internal(logError, error.description);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // show ad
        [viewController.view addSubview:self.ad];
        [self.ad showAd];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad destroy];
        self.ad = nil;
    });
    self.mobileFuseAdDelegate = nil;
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.ad != nil && self.ad.isLoaded;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISMobileFuseAdapter *adapter = (ISMobileFuseAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
