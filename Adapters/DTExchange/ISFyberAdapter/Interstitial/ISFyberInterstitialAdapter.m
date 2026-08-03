//
//  ISFyberInterstitialAdapter.m
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISFyberInterstitialAdapter.h"
#import "ISFyberInterstitialDelegate.h"
#import "ISFyberAdapter+Internal.h"
#import "ISFyberAdapter.h"
#import "ISFyberConstants.h"

@interface ISFyberInterstitialAdapter ()

@property (nonatomic, strong) IAAdSpot                    *interstitialAdSpot;
@property (nonatomic, strong) IAFullscreenUnitController   *interstitialUnitController;
@property (nonatomic, strong) IAVideoContentController     *interstitialContentController;
@property (nonatomic, strong) IAMRAIDContentController     *interstitialMRAIDContentController;
@property (nonatomic, strong) ISFyberInterstitialDelegate  *interstitialAdDelegate;

@end

@implementation ISFyberInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *spotId = [adData getString:spotIdKey];
    LogAdapterApi_Internal(logSpotId, spotId);

    if (!spotId || spotId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, spotIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    self.interstitialAdDelegate = [[ISFyberInterstitialDelegate alloc] initWithDelegate:delegate];

    NSString *serverData = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self initiateFyberInterstitialWithSpotId:spotId];

        if (!self.interstitialAdSpot || !self.interstitialUnitController) {
            LogAdapterApi_Internal(logError, errorLoadFailed);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ERROR_CODE_GENERIC
                                      errorMessage:errorLoadFailed];
            return;
        }

        __weak typeof(self) weakSelf = self;
        void (^completion)(IAAdSpot *_Nullable, IAAdModel *_Nullable, NSError *_Nullable) = ^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error) {
            [weakSelf handleLoadWithAdSpot:adSpot error:error delegate:delegate];
        };

        if (!serverData) {
            [self.interstitialAdSpot fetchAdWithCompletion:completion];
        } else {
            [self.interstitialAdSpot loadAdWithMarkup:serverData withCompletion:completion];
        }
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:errorShowFailed}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.interstitialAdDelegate.viewControllerForPresentingModalView = viewController;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialUnitController showAdAnimated:NO completion:nil];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialUnitController != nil && [self.interstitialUnitController isReady];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.interstitialAdSpot = nil;
    self.interstitialUnitController = nil;
    self.interstitialContentController = nil;
    self.interstitialMRAIDContentController = nil;
    self.interstitialAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)handleLoadWithAdSpot:(IAAdSpot *)adSpot
                       error:(NSError *)error
                    delegate:(id<ISInterstitialAdDelegate>)delegate {
    if (error || adSpot.activeUnitController != self.interstitialUnitController) {
        ISAdapterErrorType errorType = (error.code == fyberNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
        NSInteger errorCode = error ? error.code : ERROR_CODE_GENERIC;
        NSString *errorMessage = error ? error.description : errorLoadFailed;
        LogAdapterDelegate_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:errorType
                                     errorCode:errorCode
                                  errorMessage:errorMessage];
    } else {
        LogAdapterDelegate_Internal(logCallbackEmpty);
        [delegate adDidLoad];
    }
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISFyberAdapter *adapter = (ISFyberAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

- (IAAdRequest *)getRequestForSpotId:(NSString *)spotId {
    return [IAAdRequest build:^(id<IAAdRequestBuilder> _Nonnull builder) {
        builder.spotID = spotId;
        builder.timeout = requestTimeOut;
    }];
}

- (void)initiateFyberInterstitialWithSpotId:(NSString *)spotId {
    IAAdRequest *request = [self getRequestForSpotId:spotId];

    self.interstitialContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder) {
        builder.videoContentDelegate = self.interstitialAdDelegate;
    }];

    self.interstitialMRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder) {
    }];

    self.interstitialUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder> _Nonnull builder) {
        builder.unitDelegate = self.interstitialAdDelegate;
        [builder addSupportedContentController:self.interstitialContentController];
        [builder addSupportedContentController:self.interstitialMRAIDContentController];
    }];

    self.interstitialAdSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
        builder.adRequest = request;
        builder.mediationType = [IAMediationIronSource new];
        [builder addSupportedUnitController:self.interstitialUnitController];
    }];
}

@end
