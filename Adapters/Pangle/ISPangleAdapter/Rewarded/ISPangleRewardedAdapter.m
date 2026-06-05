//
//  ISPangleRewardedAdapter.m
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISPangleRewardedAdapter.h"
#import "ISPangleRewardedDelegate.h"
#import "ISPangleAdapter+Internal.h"
#import "ISPangleAdapter.h"
#import "ISPangleConstants.h"

@interface ISPangleRewardedAdapter ()

@property (nonatomic, strong) PAGRewardedAd           *rewardedAd;
@property (nonatomic, strong) ISPangleRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, assign) BOOL                    isAdAvailable;

@end

@implementation ISPangleRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    // validate slotId
    if (!slotId || slotId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingSlotId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISPangleAdapter *adapter = (ISPangleAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    if ([adapter isCoppaChildUser]) {
        NSError *error = [adapter childError];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.description];
        return;
    }

    self.rewardedAdDelegate = [[ISPangleRewardedDelegate alloc] initWithDelegate:delegate];
    self.isAdAvailable = NO;

    PAGRewardedRequest *request = [PAGRewardedRequest request];
    request.adString = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        __weak ISPangleRewardedAdapter *weakSelf = self;
        [PAGRewardedAd loadAdWithSlotID:slotId
                                request:request
                      completionHandler:^(PAGRewardedAd * _Nullable rewardedAd, NSError * _Nullable error) {
            __typeof__(self) strongSelf = weakSelf;
            if (error || !rewardedAd) {
                NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
                NSString *description = error ? error.description : [NSString stringWithFormat:logLoadFailed, networkName];
                ISAdapterErrorType errorType = (code == pangleNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
                LogInternal_Error(logError, description);
                [delegate adDidFailToLoadWithErrorType:errorType
                                             errorCode:code
                                          errorMessage:description];
                return;
            }

            rewardedAd.delegate = strongSelf.rewardedAdDelegate;
            strongSelf.rewardedAd = rewardedAd;
            strongSelf.isAdAvailable = YES;

            [delegate adDidLoad];
        }];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISPangleAdapter *adapter = (ISPangleAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    if ([adapter isCoppaChildUser]) {
        NSError *error = [adapter childError];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.description];
        return;
    }

    if ([self isAdAvailableWithAdData:adData]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rewardedAd presentFromRootViewController:viewController];
        });
    } else {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:logShowFailed}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
    }
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.isAdAvailable;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
    self.isAdAvailable = NO;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    ISPangleAdapter *adapter = (ISPangleAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithSlotId:slotId
                                 delegate:delegate];
}

@end
