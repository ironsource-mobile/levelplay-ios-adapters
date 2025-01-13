//
//  ISAppLovinRewardedVideoDelegate.m
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISAppLovinRewardedVideoDelegate.h>

@implementation ISAppLovinRewardedVideoDelegate


- (instancetype)initWithZoneId:(NSString *)zoneId
                       adapter:(ISAppLovinAdapter *)adapter
                       delegate:(id<ISAppLovinRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        _zoneId = zoneId;
        _adapter = adapter;
        _delegate = delegate;
    }
    
    return self;
}


#pragma mark - ALAdLoadDelegate

/**
 * The SDK invokes this method when an ad is loaded by the AdService.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param adService AdService that loaded the ad.
 * @param ad        Ad that was loaded.
 */
- (void)adService:(ALAdService *)adService
        didLoadAd:(ALAd *)ad {
    [_delegate onRewardedVideoDidLoad:_zoneId];
}

/**
 * The SDK invokes this method when an ad load fails.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param adService AdService that failed to load an ad.
 * @param code      An error code that corresponds to one of the constants defined in ALErrorCodes.h.
 */
- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    [_adapter disposeRewardedVideoAdWithZoneId:_zoneId];
    [_delegate onRewardedVideoDidFailToLoad:_zoneId
                                  errorCode:code];
}

#pragma mark - ALAdDisplayDelegate

/**
 * The SDK invokes this when the ad is displayed in the view.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad    Ad that was just displayed.
 * @param view  Ad view in which the ad was displayed.
 */
- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    [_delegate onRewardedVideoDidOpen:_zoneId];
}

/**
 * The SDK invokes this method when the ad is clicked in the view.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad    Ad that was just clicked.
 * @param view  Ad view in which the ad was clicked.
 */
- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
    [_delegate onRewardedVideoDidClick:_zoneId];
}

/**
 * The SDK invokes this method when the ad is hidden from the view. This occurs when the user "X"es out of an interstitial.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad    Ad that was just hidden.
 * @param view  Ad view in which the ad was hidden.
 */
- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    [_adapter disposeRewardedVideoAdWithZoneId:_zoneId];
    [_delegate onRewardedVideoDidClose:_zoneId];
}

#pragma mark - ALAdVideoPlaybackDelegate

/**
 * The SDK invokes this method when a video starts playing in an ad.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad  Ad in which video playback began.
 */
- (void)videoPlaybackBeganInAd:(ALAd *)ad {
    [_delegate onRewardedVideoDidStart:_zoneId];
}

/**
 * The SDK invokes this method when a video stops playing in an ad.
 *
 * The SDK invokes this method on the main UI thread.
 *
 * @param ad                Ad in which video playback ended.
 * @param percentPlayed     How much of the video was watched, as a percent, between 0 and 100.
 * @param wasFullyWatched   Whether or not the video was watched to 95% or more of completion.
 */
- (void)videoPlaybackEndedInAd:(ALAd *)ad
             atPlaybackPercent:(NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
    
    [_delegate onRewardedVideoDidEnd:_zoneId];
    if (wasFullyWatched) {
        [_delegate onRewardedVideoDidReceiveReward:_zoneId];
    }
}

#pragma mark - ALAdRewardDelegate

/**
 * The SDK invokes this method if a user viewed a rewarded video and their reward was approved by the AppLovin server.
 *
 * If you use reward validation for incentivized videos, the SDK invokes this method if it contacted AppLovin successfully. This means the SDK believes the
 * reward is legitimate and you should award it.
 *
 * <b>Tip:</b> refresh the user’s balance from your server at this point rather than relying on local data that could be tampered with on jailbroken devices.
 *
 * The @c response @c NSDictionary will typically include the keys @c "currency" and @c "amount", which point to @c NSStrings that contain the name and amount of the
 * virtual currency that you may award.
 *
 * @param ad       Ad that was viewed.
 * @param response Dictionary that contains response data from the server, including @c "currency" and @c "amount".
 */
- (void)rewardValidationRequestForAd:(ALAd *)ad
              didSucceedWithResponse:(NSDictionary *)response {
}

/**
 * The SDK invokes this method if it was able to contact AppLovin, but the user has already received the maximum number of coins you allowed per day in the web
 * UI, and so is ineligible for a reward.
 *
 * @param ad       Ad that was viewed.
 * @param response Dictionary that contains response data from the server.
 */
- (void)rewardValidationRequestForAd:(ALAd *)ad
          didExceedQuotaWithResponse:(NSDictionary *)response {
}

/**
 * The SDK invokes this method if the AppLovin server rejected the reward request. The usual cause of this is that the user fails to pass an anti-fraud check.
 *
 * @param ad       Ad that was viewed.
 * @param response Dictionary that contains response data from the server.
 */
- (void)rewardValidationRequestForAd:(ALAd *)ad
             wasRejectedWithResponse:(NSDictionary *)response {
}

/**
 * The SDK invokes this method if it was unable to contact AppLovin, and so AppLovin will not issue a ping to your S2S rewarded callback server.
 *
 * @param ad           Ad that was viewed.
 * @param responseCode A failure code that corresponds to a constant defined in ALErrorCodes.h.
 */
- (void)rewardValidationRequestForAd:(ALAd *)ad
                    didFailWithError:(NSInteger)responseCode {
}

@end
