//
//  ISVerveRewardedAdapter.m
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISVerveRewardedAdapter.h"
#import "ISVerveRewardedDelegate.h"
#import "ISVerveAdapter+Internal.h"

@interface ISVerveRewardedAdapter ()

@property (nonatomic, strong) HyBidRewardedAd *ad;
@property (nonatomic, strong) ISVerveRewardedDelegate *adDelegate;

@end

@implementation ISVerveRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *zoneId = [adData getString:zoneIdKey];
    LogAdapterApi_Internal(logZoneId, zoneId);

    if (!zoneId || zoneId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingZoneId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISVerveRewardedDelegate *adDelegate = [[ISVerveRewardedDelegate alloc] initWithDelegate:delegate];
    self.adDelegate = adDelegate;
    self.ad = [[HyBidRewardedAd alloc] initWithDelegate:adDelegate];
    [self.ad prepareAdWithContent:adData.serverData];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad showFromViewController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.ad != nil && [self.ad isReady];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    self.ad = nil;
    self.adDelegate = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISVerveAdapter *adapter = (ISVerveAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
