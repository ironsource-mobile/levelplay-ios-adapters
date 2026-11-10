//
//  ISVungleRewardedDelegate.m
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISVungleRewardedDelegate.h"
#import "ISVungleConstants.h"

@implementation ISVungleRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - VungleRewardedDelegate

- (void)rewardedAdDidLoad:(VungleRewarded *)rewarded {
    NSString *creativeId = rewarded.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        [self.delegate adDidLoadWithExtraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)rewardedAdDidFailToLoad:(VungleRewarded *)rewarded
                      withError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error.description);

    BOOL isNoFill = (error.code == VungleErrorAdNoFill);
    ISAdapterErrorType errorType = isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)rewardedAdDidTrackImpression:(VungleRewarded *)rewarded {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)rewardedAdDidFailToPresent:(VungleRewarded *)rewarded
                         withError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error.description);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)rewardedAdDidClick:(VungleRewarded *)rewarded {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)rewardedAdDidRewardUser:(VungleRewarded *)rewarded {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

- (void)rewardedAdDidClose:(VungleRewarded *)rewarded {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
