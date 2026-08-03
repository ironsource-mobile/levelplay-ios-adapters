//
//  ISFyberBannerAdapter.m
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrors.h>
#import "ISFyberBannerAdapter.h"
#import "ISFyberBannerDelegate.h"
#import "ISFyberAdapter+Internal.h"
#import "ISFyberAdapter.h"
#import "ISFyberConstants.h"

@interface ISFyberBannerAdapter ()

@property (nonatomic, strong) IAAdSpot                 *bannerAdSpot;
@property (nonatomic, strong) IAViewUnitController      *bannerUnitController;
@property (nonatomic, strong) IAMRAIDContentController  *bannerMRAIDContentController;
@property (nonatomic, strong) ISFyberBannerDelegate     *bannerAdDelegate;

@end

@implementation ISFyberBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
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

    CGSize bannerSize = [self getBannerSize:size];

    if (CGSizeEqualToSize(bannerSize, CGSizeZero)) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:errorUnsupportedBannerSize}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.bannerAdDelegate = [[ISFyberBannerDelegate alloc] initWithDelegate:delegate];

    NSString *serverData = adData.serverData;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdDelegate.viewControllerForPresentingModalView = viewController;
        [self initiateFyberBannerWithSpotId:spotId];

        if (!self.bannerAdSpot || !self.bannerUnitController) {
            LogAdapterApi_Internal(logError, errorLoadFailed);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ERROR_BN_LOAD_EXCEPTION
                                      errorMessage:errorLoadFailed];
            return;
        }

        self.bannerUnitController.adView.bounds = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        LogAdapterApi_Internal(logLoadBanner, (int)bannerSize.width, (int)bannerSize.height, spotId);

        __weak typeof(self) weakSelf = self;
        void (^completion)(IAAdSpot *_Nullable, IAAdModel *_Nullable, NSError *_Nullable) = ^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error) {
            [weakSelf handleLoadWithAdSpot:adSpot error:error delegate:delegate];
        };

        if (!serverData) {
            [self.bannerAdSpot fetchAdWithCompletion:completion];
        } else {
            [self.bannerAdSpot loadAdWithMarkup:serverData withCompletion:completion];
        }
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdSpot = nil;
        self.bannerUnitController = nil;
        self.bannerMRAIDContentController = nil;
        self.bannerAdDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)handleLoadWithAdSpot:(IAAdSpot *)adSpot
                       error:(NSError *)error
                    delegate:(id<ISBannerAdDelegate>)delegate {
    if (error || adSpot.activeUnitController != self.bannerUnitController) {
        ISAdapterErrorType errorType = (error.code == fyberNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
        NSInteger errorCode = error ? error.code : ERROR_BN_LOAD_EXCEPTION;
        NSString *errorMessage = error ? error.description : errorLoadFailed;
        LogAdapterDelegate_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:errorType
                                     errorCode:errorCode
                                  errorMessage:errorMessage];
    } else {
        LogAdapterDelegate_Internal(logCallbackEmpty);
        [delegate adDidLoadWithView:self.bannerUnitController.adView];
    }
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISFyberAdapter *adapter = (ISFyberAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

- (CGSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return CGSizeMake(bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return CGSizeMake(rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGSizeMake(leaderboardWidth, leaderboardHeight);
        } else {
            return CGSizeMake(bannerWidth, bannerHeight);
        }
    }

    return CGSizeZero;
}

- (IAAdRequest *)getRequestForSpotId:(NSString *)spotId {
    return [IAAdRequest build:^(id<IAAdRequestBuilder> _Nonnull builder) {
        builder.spotID = spotId;
        builder.timeout = requestTimeOut;
    }];
}

- (void)initiateFyberBannerWithSpotId:(NSString *)spotId {
    IAAdRequest *request = [self getRequestForSpotId:spotId];

    self.bannerMRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder) {
        builder.MRAIDContentDelegate = self.bannerAdDelegate;
    }];

    self.bannerUnitController = [IAViewUnitController build:^(id<IAViewUnitControllerBuilder> _Nonnull builder) {
        builder.unitDelegate = self.bannerAdDelegate;
        [builder addSupportedContentController:self.bannerMRAIDContentController];
    }];

    self.bannerAdSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
        builder.adRequest = request;
        builder.mediationType = [IAMediationIronSource new];
        [builder addSupportedUnitController:self.bannerUnitController];
    }];
}

@end
