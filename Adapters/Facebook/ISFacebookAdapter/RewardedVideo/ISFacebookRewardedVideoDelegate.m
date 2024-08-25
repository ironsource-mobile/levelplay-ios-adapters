//
//  ISFacebookRewardedVideoDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import "ISFacebookRewardedVideoDelegate.h"
#import "ISFacebookConstants.h"

@implementation ISFacebookRewardedVideoDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}

/**
 Sent when an ad has been successfully loaded.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

/**
 Sent after an FBRewardedVideoAd fails to load the ad.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd
       didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);
    
    // Report load failure
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];

    // For Rewarded Videos, when an adapter receives a failure reason from the network, it will pass it to the Mediation.
    if (error) {
        NSInteger errorCode = error.code == kMetaNoFillErrorCode ? ERROR_RV_LOAD_NO_FILL : error.code;
        NSError *rewardedVideoError = [NSError errorWithDomain:kAdapterName
                                                          code:errorCode
                                                      userInfo:@{NSLocalizedDescriptionKey:error.description}];
        
        [self.delegate adapterRewardedVideoDidFailToLoadWithError:rewardedVideoError];
    }
}

/**
 Sent immediately before the impression of an FBRewardedVideoAd object will be logged.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

/**
 Sent after an ad has been clicked by the person.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidClick];
}

/**
 Sent after the FBRewardedVideoAd object has finished playing the video successfully.
 Reward the user on this callback.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
    [self.delegate adapterRewardedVideoDidEnd];
}

/**
 Sent after an FBRewardedVideoAd object has been dismissed from the screen, returning control to your application.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterRewardedVideoDidClose];
}

@end
