//
//  ISVerveRewardedDelegate.m
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVerveRewardedDelegate.h"
#import "ISVerveConstants.h"
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISVerveRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad successfully loaded and ready to be displayed.
- (void)rewardedDidLoad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

/// calls this method when ad was not loaded for some reasons
/// @param error the reason of failing loading
- (void)rewardedDidFailWithError:(NSError * _Null_unspecified)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);
    ISAdapterErrorType errorType = (error.code == HyBidErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// calls this method when ad has been presented to the user
- (void)rewardedDidTrackImpression {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// calls this method when user clicked on the ad
- (void)rewardedDidTrackClick {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// calls this method when the user has finished watching the video and endcards if they exist
- (void)onReward {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

/// calls this method when ad was dismissed by user action using the close button
- (void)rewardedDidDismiss {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
