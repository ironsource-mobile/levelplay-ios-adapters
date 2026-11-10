//
//  ISAdMobRewardedAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISAdMobRewardedAdapter.h"
#import "ISAdMobRewardedDelegate.h"
#import "ISAdMobAdapter+Internal.h"
#import "ISAdMobAdapter.h"
#import "ISAdMobConstants.h"

@interface ISAdMobRewardedAdapter ()

@property (nonatomic, strong) GADRewardedAd            *rewardedAd;
@property (nonatomic, strong) ISAdMobRewardedDelegate  *rewardedAdDelegate;
@property (nonatomic, assign) BOOL                      adAvailability;

@end

@implementation ISAdMobRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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

    GADRewardedAdLoadCompletionHandler loadHandler = ^(GADRewardedAd *_Nullable rewardedAd, NSError *_Nullable error) {
        if (error) {
            LogAdapterDelegate_Internal(logLoadFailed, networkName, error);
            ISAdapterErrorType errorType = (error.code == GADErrorNoFill) ?
                ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
            [delegate adDidFailToLoadWithErrorType:errorType
                                         errorCode:error.code
                                      errorMessage:error.localizedDescription];
            return;
        }

        if (!rewardedAd) {
            NSString *errorMessage = [NSString stringWithFormat:errorAdIsNil, adFormatRewarded];
            LogAdapterDelegate_Internal(logError, errorMessage);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ERROR_CODE_GENERIC
                                      errorMessage:errorMessage];
            return;
        }

        self.rewardedAd = rewardedAd;
        self.adAvailability = YES;

        NSString *creativeId = rewardedAd.responseInfo.responseIdentifier;
        LogAdapterDelegate_Internal(logCreativeId, creativeId);

        if (creativeId.length) {
            NSDictionary *extraData = @{creativeIdKey: creativeId};
            [delegate adDidLoadWithExtraData:extraData];
        } else {
            [delegate adDidLoad];
        }
    };

    if (adData.serverData) {
        [GADRewardedAd loadWithAdResponseString:adData.serverData
                              completionHandler:loadHandler];
    } else {
        GADRequest *request = [adapter createGADRequestWithAdData:adData.adUnitData];
        [GADRewardedAd loadWithAdUnitID:adUnitId
                                request:request
                      completionHandler:loadHandler];
    }
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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
        self.rewardedAdDelegate = [[ISAdMobRewardedDelegate alloc] initWithDelegate:delegate];
        self.rewardedAd.fullScreenContentDelegate = self.rewardedAdDelegate;

        [self.rewardedAd presentFromRootViewController:viewController
                              userDidEarnRewardHandler:^{
            LogAdapterDelegate_Internal(logAdRewarded);
            [delegate adRewarded];
        }];

        self.adAvailability = NO;
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.adAvailability;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.adAvailability = NO;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
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

    GADRewardedSignalRequest *request = [[GADRewardedSignalRequest alloc] initWithSignalType:requesterType];
    [adapter collectBiddingDataWithSignalRequest:request
                                          adData:adData
                                        delegate:delegate];
}

@end
