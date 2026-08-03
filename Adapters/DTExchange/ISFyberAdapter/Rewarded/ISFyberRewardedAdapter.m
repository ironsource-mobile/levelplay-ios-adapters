//
//  ISFyberRewardedAdapter.m
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISFyberRewardedAdapter.h"
#import "ISFyberRewardedDelegate.h"
#import "ISFyberAdapter+Internal.h"
#import "ISFyberAdapter.h"
#import "ISFyberConstants.h"

@interface ISFyberRewardedAdapter ()

@property (nonatomic, strong) IAAdSpot                  *rewardedVideoAdSpot;
@property (nonatomic, strong) IAFullscreenUnitController *rewardedVideoUnitController;
@property (nonatomic, strong) IAVideoContentController   *rewardedVideoContentController;
@property (nonatomic, strong) IAMRAIDContentController   *rewardedVideoMRAIDContentController;
@property (nonatomic, strong) ISFyberRewardedDelegate    *rewardedVideoAdDelegate;

@end

@implementation ISFyberRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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

    self.rewardedVideoAdDelegate = [[ISFyberRewardedDelegate alloc] initWithDelegate:delegate];

    NSString *serverData = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self initiateFyberRewardedVideoWithSpotId:spotId];

        if (!self.rewardedVideoAdSpot || !self.rewardedVideoUnitController) {
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
            [self.rewardedVideoAdSpot fetchAdWithCompletion:completion];
        } else {
            [self.rewardedVideoAdSpot loadAdWithMarkup:serverData withCompletion:completion];
        }
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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

    NSString *dynamicUserId = [self dynamicUserId];
    if (dynamicUserId.length) {
        LogAdapterApi_Internal(logSetUserId, dynamicUserId);
        IASDKCore.sharedInstance.userID = dynamicUserId;
    }

    self.rewardedVideoAdDelegate.viewControllerForPresentingModalView = viewController;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedVideoUnitController showAdAnimated:YES completion:nil];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedVideoUnitController != nil && [self.rewardedVideoUnitController isReady];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);
    self.rewardedVideoAdSpot = nil;
    self.rewardedVideoUnitController = nil;
    self.rewardedVideoContentController = nil;
    self.rewardedVideoMRAIDContentController = nil;
    self.rewardedVideoAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)handleLoadWithAdSpot:(IAAdSpot *)adSpot
                       error:(NSError *)error
                    delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    if (error || adSpot.activeUnitController != self.rewardedVideoUnitController) {
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

- (void)initiateFyberRewardedVideoWithSpotId:(NSString *)spotId {
    IAAdRequest *request = [self getRequestForSpotId:spotId];

    self.rewardedVideoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder) {
        builder.videoContentDelegate = self.rewardedVideoAdDelegate;
    }];

    self.rewardedVideoMRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder) {
    }];

    self.rewardedVideoUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder> _Nonnull builder) {
        builder.unitDelegate = self.rewardedVideoAdDelegate;
        [builder addSupportedContentController:self.rewardedVideoMRAIDContentController];
        [builder addSupportedContentController:self.rewardedVideoContentController];
    }];

    self.rewardedVideoAdSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
        builder.adRequest = request;
        builder.mediationType = [IAMediationIronSource new];
        [builder addSupportedUnitController:self.rewardedVideoUnitController];
    }];
}

@end
