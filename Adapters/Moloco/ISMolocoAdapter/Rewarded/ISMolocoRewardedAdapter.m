//
//  ISMolocoRewardedAdapter.m
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MolocoSDK/MolocoSDK-Swift.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMolocoRewardedAdapter.h"
#import "ISMolocoRewardedDelegate.h"
#import "ISMolocoAdapter+Internal.h"
#import "ISMolocoAdapter.h"
#import "ISMolocoConstants.h"

@interface ISMolocoRewardedAdapter ()

@property (nonatomic, strong) id<MolocoRewardedInterstitial>      rewardedAd;
@property (nonatomic, strong) ISMolocoRewardedDelegate            *rewardedAdDelegate;

@end

@implementation ISMolocoRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    // Validate adUnitId
    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    // Validate serverData
    NSString *serverData = adData.serverData;
    if (!serverData) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, serverDataKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    // Create rewarded ad
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create rewarded ad delegate
        self.rewardedAdDelegate = [[ISMolocoRewardedDelegate alloc] initWithDelegate:delegate];

        MolocoCreateAdParams *params = [[MolocoCreateAdParams alloc] initWithAdUnit:adUnitId
                                                                           mediation:mediationName];

        self.rewardedAd = [[Moloco shared] createRewardedWithParams:params];
        self.rewardedAd.rewardedDelegate = self.rewardedAdDelegate;

        // Load ad
        [self.rewardedAd loadWithBidResponse:serverData];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        LogAdapterApi_Internal(logError, errorRewardedNotAvailable);
        [delegate adDidFailToShowWithErrorCode:ERROR_CODE_NO_ADS_TO_SHOW
                                  errorMessage:errorRewardedNotAvailable];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd showFrom:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.rewardedAd.isReady;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.rewardedAd destroy];
    self.rewardedAd.rewardedDelegate = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd = nil;
    });
    self.rewardedAdDelegate = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISMolocoAdapter *adapter = (ISMolocoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        [delegate failureWithError:error.localizedDescription];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
