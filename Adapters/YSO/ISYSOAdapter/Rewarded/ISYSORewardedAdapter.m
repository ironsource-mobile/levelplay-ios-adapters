//
//  ISYSORewardedAdapter.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISYSORewardedAdapter.h"
#import "ISYSORewardedDelegate.h"
#import "ISYSOAdapter+Internal.h"

@interface ISYSORewardedAdapter ()

@property (nonatomic, strong) ISYSORewardedDelegate *rewardedAdDelegate;

@end

@implementation ISYSORewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementKey = [adData getString:placementKeyKey];
    LogAdapterApi_Internal(logPlacementKey, placementKey);

    if (!placementKey || placementKey.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, placementKeyKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    self.rewardedAdDelegate = [[ISYSORewardedDelegate alloc] initWithDelegate:delegate];

    [YsoNetwork rewardedLoadWithKey:placementKey
                             json:adData.serverData
                           onLoad:^(e_ActionError error) {
        [self.rewardedAdDelegate handleOnLoad:error];
    }];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementKey = [adData getString:placementKeyKey];
    LogAdapterApi_Internal(logPlacementKey, placementKey);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [YsoNetwork rewardedShowWithKey:placementKey
                       viewController:viewController
                            onDisplay:^(YNWebView *_Nullable view) {
            [self.rewardedAdDelegate handleOnDisplay:view];
        }
                              onClick:^{
            [self.rewardedAdDelegate handleOnClick];
        }
                              onClose:^(BOOL display, BOOL complete) {
            [self.rewardedAdDelegate handleOnClose:display complete:complete];
        }];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return [YsoNetwork rewardedIsReadyWithKey:[adData getString:placementKeyKey]];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISYSOAdapter *adapter = (ISYSOAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
