//
//  ISUnityAdsRewardedVideoDelegate.m
//  ISUnityAdsAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISUnityAdsRewardedVideoDelegate.h>

@implementation ISUnityAdsRewardedVideoDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISUnityAdsRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark UnityAdsLoadDelegate

/**
 *  Callback triggered when a load request has successfully filled the specified placementId with an ad that is ready to show.
 *  @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsAdLoaded:(nonnull NSString *)placementId {
    [self.delegate onRewardedVideoDidLoad:self.placementId];
}

/**
 * Called when load request has failed to load an ad for a requested placement.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 * @param error UnityAdsLoadError
 * @param message A human readable error message
 */
- (void)unityAdsAdFailedToLoad:(nonnull NSString *)placementId
                     withError:(UnityAdsLoadError)error
                   withMessage:(nonnull NSString *)message {
    [self.delegate onRewardedVideoDidFailToLoad:self.placementId
                                      withError:error];
}

#pragma mark UnityAdsShowDelegate

/**
 * Called when UnityAds has started to show ad with a specific placement.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsShowStart:(nonnull NSString *)placementId {
    [self.delegate onRewardedVideoDidOpen:self.placementId];
}

/**
 * Called when UnityAds has failed to show a specific placement with an error message and error category.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 * @param error
 *           if `kUnityShowErrorNotInitialized`, show failed due to SDK not initialized.
 *           if `kUnityShowErrorNotReady`, show failed due to placement  not being ready.
 *           if `kUnityShowErrorVideoPlayerError`, show failed due to video player.
 *           if `kUnityShowErrorInvalidArgument`, show failed due to invalid arguments.
 *           if `kUnityShowErrorNoConnection`, show failed due to internet connection.
 *           if `kUnityShowErrorAlreadyShowing`, show failed due to ad is already being showen.
 *           if `kUnityShowErrorInternalError`, show failed due to environment or internal services.
 * @param message A human readable error message
 */
- (void)unityAdsShowFailed:(nonnull NSString *)placementId
                 withError:(UnityAdsShowError)error
               withMessage:(nonnull NSString *)message {
    [self.delegate onRewardedVideoShowFail:self.placementId
                                 withError:error
                                andMessage:message];
}

/**
 * Called when UnityAds has received a click while showing ad with a specific placement.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsShowClick:(nonnull NSString *)placementId {
    [self.delegate onRewardedVideoDidClick:self.placementId];
}

/**
 * Called when UnityAds completes show operation successfully for a placement with completion state.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 * @param state An enum value indicating the finish state of the ad. Possible values are `Completed`, `Skipped`.
 */
- (void)unityAdsShowComplete:(nonnull NSString *)placementId
             withFinishState:(UnityAdsShowCompletionState)state {
    [self.delegate onRewardedVideoDidShowComplete:self.placementId
                                  withFinishState:state];
}

@end
