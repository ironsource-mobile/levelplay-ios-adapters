//
//  ISFacebookRewardedVideoDelegate.m
//  ISFacebookAdapter
//
//  Created by Hadar Pur on 01/08/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//

#import "ISFacebookRewardedVideoDelegate.h"

@implementation ISFacebookRewardedVideoDelegate

- (instancetype)initWithPlacementID:(NSString *)placementID
                        andDelegate:(id<ISFacebookRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _placementID = placementID;
        _delegate = delegate;
    }
    return self;
}

/**
 Sent when an ad has been successfully loaded.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
    [_delegate onRewardedVideoDidLoad:_placementID];
}

/**
 Sent after an FBRewardedVideoAd fails to load the ad.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd
       didFailWithError:(NSError *)error {
    
    [_delegate onRewardedVideoDidFailToLoad:_placementID
                                  withError:error];
}

/**
 Sent immediately before the impression of an FBRewardedVideoAd object will be logged.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
    [_delegate onRewardedVideoDidOpen:_placementID];
}

/**
 Sent after an ad has been clicked by the person.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
    [_delegate onRewardedVideoDidClick:_placementID];
}

/**
 Sent after the FBRewardedVideoAd object has finished playing the video successfully.
 Reward the user on this callback.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
    [_delegate onRewardedVideoDidEnd:_placementID];
}

/**
 Sent after an FBRewardedVideoAd object has been dismissed from the screen, returning control to your application.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
    [_delegate onRewardedVideoDidClose:_placementID];
}

@end
