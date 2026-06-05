//
//  ISUnityAdsRewardedVideoDelegate.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <ISUnityAdsRewardedVideoDelegate.h>

@interface ISUnityAdsRewardedVideoDelegate()
@property (nonatomic, copy) ISUnityAdsEventSenderBlock _Nullable eventSender;
@end

@implementation ISUnityAdsRewardedVideoDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISUnityAdsRewardedVideoDelegateWrapper>)delegate
                        eventSender:(ISUnityAdsEventSenderBlock)eventSender {
    self = [super init];

    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
        self.eventSender = eventSender;
    }

    return self;
}

#pragma mark UnityAdsLoadDelegate

/**
 *  Callback triggered when a load request has successfully filled the specified placementId with an ad that is ready to show.
 *  @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsAdLoaded:(nonnull NSString *)placementId {
    if (self.delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_onUnityAdsAdLoaded");
    }
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
    if (self.delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_onUnityAdsFailedToLoad");
    }
    [self.delegate onRewardedVideoDidFailToLoad:self.placementId
                                      withError:error];
}

#pragma mark UnityAdsShowDelegate

/**
 * Called when UnityAds has started to show ad with a specific placement.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsShowStart:(nonnull NSString *)placementId {
    if (self.delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_onUnityAdsShowStart");
    }
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
    if (self.delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_onUnityAdsShowFailure");
    }
    [self.delegate onRewardedVideoShowFail:self.placementId
                                 withError:error
                                andMessage:message];
}

/**
 * Called when UnityAds has received a click while showing ad with a specific placement.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 */
- (void)unityAdsShowClick:(nonnull NSString *)placementId {
    if (self.delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_onUnityAdsShowClick");
    }
    [self.delegate onRewardedVideoDidClick:self.placementId];
}

/**
 * Called when UnityAds completes show operation successfully for a placement with completion state.
 * @param placementId The ID of the placement as defined in Unity Ads admin tools.
 * @param state An enum value indicating the finish state of the ad. Possible values are `Completed`, `Skipped`.
 */
- (void)unityAdsShowComplete:(nonnull NSString *)placementId
             withFinishState:(UnityAdsShowCompletionState)state {
    if (self.delegate == nil && self.eventSender != nil) {
        self.eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_onUnityAdsShowComplete");
    }
    [self.delegate onRewardedVideoDidShowComplete:self.placementId
                                  withFinishState:state];
}

@end
