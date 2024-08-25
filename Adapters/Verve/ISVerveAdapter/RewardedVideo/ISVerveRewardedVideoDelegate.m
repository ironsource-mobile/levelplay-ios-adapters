//
//  ISVerveRewardedVideoDelegate.m
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISVerveRewardedVideoDelegate.h"

@implementation ISVerveRewardedVideoDelegate

- (instancetype)initWithZoneId:(NSString *)zoneId
                    andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _zoneId = zoneId;
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad successfully loaded and ready to be displayed.
- (void)rewardedDidLoad {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

/// calls this method when ad was not loaded for some reasons
/// @param error the reason of failing loading
- (void)rewardedDidFailWithError:(NSError * _Null_unspecified)error {
    LogAdapterDelegate_Internal(@"zoneId = %@ with error = %@", self.zoneId, error);
        
    NSError *smashError = error.code == HyBidErrorCodeNoFill ? [ISError createError:ERROR_RV_LOAD_NO_FILL
                                                                                  withMessage:@"Verve no fill"] : error;
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
}

/// calls this method when ad has been presented to the user
- (void)rewardedDidTrackImpression {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

/// calls this method when user clicked on the ad
- (void)rewardedDidTrackClick {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterRewardedVideoDidClick];
}

/// calls this method when the user has finished watching the video and endcards if they exist
- (void)onReward {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterRewardedVideoDidEnd];
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

/// calls this method when ad was dismissed by user action using the close button
- (void)rewardedDidDismiss {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterRewardedVideoDidClose];
}

@end
