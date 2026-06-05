//
//  ISPangleInterstitialAdapter.m
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISPangleInterstitialAdapter.h"
#import "ISPangleInterstitialDelegate.h"
#import "ISPangleAdapter+Internal.h"
#import "ISPangleAdapter.h"
#import "ISPangleConstants.h"

@interface ISPangleInterstitialAdapter ()

@property (nonatomic, strong) PAGLInterstitialAd           *interstitialAd;
@property (nonatomic, strong) ISPangleInterstitialDelegate *interstitialAdDelegate;
@property (nonatomic, assign) BOOL                         isAdAvailable;

@end

@implementation ISPangleInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
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

    self.interstitialAdDelegate = [[ISPangleInterstitialDelegate alloc] initWithDelegate:delegate];
    self.isAdAvailable = NO;

    PAGInterstitialRequest *request = [PAGInterstitialRequest request];
    request.adString = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        __weak ISPangleInterstitialAdapter *weakSelf = self;
        [PAGLInterstitialAd loadAdWithSlotID:slotId
                                     request:request
                           completionHandler:^(PAGLInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
            __typeof__(self) strongSelf = weakSelf;
            if (error || !interstitialAd) {
                NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
                NSString *description = error ? error.description : [NSString stringWithFormat:logLoadFailed, networkName];
                ISAdapterErrorType errorType = (code == pangleNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
                LogInternal_Error(logError, description);
                [delegate adDidFailToLoadWithErrorType:errorType
                                             errorCode:code
                                          errorMessage:description];
                return;
            }

            interstitialAd.delegate = strongSelf.interstitialAdDelegate;
            strongSelf.interstitialAd = interstitialAd;
            strongSelf.isAdAvailable = YES;

            [delegate adDidLoad];
        }];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
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
            [self.interstitialAd presentFromRootViewController:viewController];
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
    return self.interstitialAd != nil && self.isAdAvailable;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
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
