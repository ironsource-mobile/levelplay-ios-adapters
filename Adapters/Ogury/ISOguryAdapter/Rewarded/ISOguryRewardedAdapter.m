//
//  ISOguryRewardedAdapter.m
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISOguryRewardedAdapter.h"
#import "ISOguryRewardedDelegate.h"
#import "ISOguryAdapter+Internal.h"
#import "ISOguryAdapter.h"
#import "ISOguryConstants.h"

@interface ISOguryRewardedAdapter ()

@property (nonatomic, strong) OguryRewardedAd          *rewardedAd;
@property (nonatomic, strong) ISOguryRewardedDelegate  *rewardedAdDelegate;

@end

@implementation ISOguryRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    self.rewardedAdDelegate = [[ISOguryRewardedDelegate alloc] initWithDelegate:delegate];

    OguryMediation *mediation = [[OguryMediation alloc] initWithName:mediationName
                                                            version:[LevelPlay sdkVersion]
                                                     adapterVersion:OguryAdapterVersion];
    self.rewardedAd = [[OguryRewardedAd alloc] initWithAdUnitId:adUnitId
                                                      mediation:mediation];
    self.rewardedAd.delegate = self.rewardedAdDelegate;
    [self.rewardedAd loadWithAdMarkup:adData.serverData];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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

    [self.rewardedAd showAdInViewController:viewController];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && [self.rewardedAd isLoaded];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
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
