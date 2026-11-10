//
//  ISMintegralRewardedDelegate.m
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDK/MTGErrorCodeConstant.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISMintegralRewardedDelegate.h"
#import "ISMintegralConstants.h"

@implementation ISMintegralRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - MTGRewardAdLoadDelegate

- (void)onAdLoadSuccess:(nullable NSString *)placementId
                 unitId:(nullable NSString *)unitId {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)onVideoAdLoadSuccess:(nullable NSString *)placementId
                      unitId:(nullable NSString *)unitId {
    NSString *creativeId = [[MTGBidRewardAdManager sharedInstance] getCreativeIdWithUnitId:unitId];
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithExtraData:extraData];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)onVideoAdLoadFailed:(nullable NSString *)placementId
                     unitId:(nullable NSString *)unitId
                      error:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(logError, error);

    BOOL isNoFill = error.code == mintegralNoFillEmptyError ||
                    error.code == kMTGErrorCodeNoAds ||
                    error.code == kMTGErrorCodeNoAdsAvailableToPlay;
    ISAdapterErrorType errorType = isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

#pragma mark - MTGRewardAdShowDelegate

- (void)onVideoAdShowSuccess:(nullable NSString *)placementId
                      unitId:(nullable NSString *)unitId {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)onVideoAdShowSuccess:(nullable NSString *)placementId
                      unitId:(nullable NSString *)unitId
                    bidToken:(nullable NSString *)bidToken {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)onVideoAdShowFailed:(nullable NSString *)placementId
                     unitId:(nullable NSString *)unitId
                  withError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(logError, error);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)onVideoAdClicked:(nullable NSString *)placementId
                  unitId:(nullable NSString *)unitId {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)onVideoPlayCompleted:(nullable NSString *)placementId
                      unitId:(nullable NSString *)unitId {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)onVideoEndCardShowSuccess:(nullable NSString *)placementId
                           unitId:(nullable NSString *)unitId {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)onVideoAdDismissed:(nullable NSString *)placementId
                    unitId:(nullable NSString *)unitId
             withConverted:(BOOL)converted
            withRewardInfo:(nullable MTGRewardAdInfo *)rewardInfo {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    if (converted) {
        [self.delegate adRewarded];
    }
}

- (void)onVideoAdDidClosed:(nullable NSString *)placementId
                    unitId:(nullable NSString *)unitId {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
