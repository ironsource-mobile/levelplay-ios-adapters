//
//  ISChartboostRewardedVideoDelegate.m
//  ISChartboostAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISChartboostRewardedVideoDelegate.h>

@implementation ISChartboostRewardedVideoDelegate

- (instancetype)initWithLocationId:(NSString *)locationId
                       andDelegate:(id<ISChartboostRewardedVideoDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        _locationId = locationId;
        _delegate = delegate;
    }
    
    return self;
}

/*!
 @brief Called after a cache call, either if an ad has been loaded from the Chartboost servers and cached, or tried to but failed.
 @param event A cache event with info related to the cached ad.
 @param error An error specifying the failure reason, or nil if the operation was successful.
 @discussion Implement to be notified of when an ad is ready to be shown after the cache method has been called.
 */
- (void)didCacheAd:(CHBCacheEvent *)event
             error:(nullable CHBCacheError *)error {
    if (error) {
        [_delegate onRewardedVideoDidFailToLoad:_locationId
                                      withError:error];
    } else {
        [_delegate onRewardedVideoDidLoad:_locationId];
    }
}

/*!
 @brief Called after a showFromViewController: call, either if the ad has been presented and an ad impression logged, or if the operation failed.
 @param event A show event with info related to the ad shown.
 @param error An error specifying the failure reason, or nil if the operation was successful.
 @discussion Implement to be notified of when the ad presentation process has finished.
 This method will be called once for each call to showFromViewController: on an interstitial or rewarded ad.
 In contrast, this may be called up to two times after showing a banner, if some error occurs after the ad has been successfully shown.
 
 A common practice consists of caching an ad here so there's an ad ready for the next time you need to show it.
 */
- (void)didShowAd:(CHBShowEvent *)event
            error:(nullable CHBShowError *)error {
    if (error) {
        [_delegate onRewardedVideoShowFail:_locationId
                                 withError:error];
    } else {
        [_delegate onRewardedVideoDidOpen:_locationId];
    }
}

/*!
 @brief Called after an ad has been clicked.
 @param event A click event with info related to the ad clicked.
 @param error An error specifying the failure reason, or nil if the operation was successful.
 @discussion Implement to be notified of when an ad has been clicked.
 If the click does not result into the opening of a link an error will be provided explaning why.
 */
- (void)didClickAd:(CHBClickEvent *)event
             error:(nullable CHBClickError *)error {
    [_delegate onRewardedVideoDidClick:_locationId
                             withError:error];
}

/*!
 @brief Called when a rewarded ad has completed playing.
 @param event A reward event with info related to the ad and the reward.
 @discussion Implement to be notified when a reward is earned.
 */
- (void)didEarnReward:(CHBRewardEvent *)event {
    [_delegate onRewardedVideoDidReceiveReward:_locationId];
    [_delegate onRewardedVideoDidEnd:_locationId];
}

/*!
 @brief Called after an ad is dismissed.
 @param event A dismiss event with info related to the dismissed ad.
 @discussion Implement to be notified of when an ad is no longer displayed.
 Note that this method won't get called for ads that failed to be shown. To handle that case implement didShowAd:error:
 You may use the error property inside the event to know if the dismissal was expected or caused by an error.
 */
- (void)didDismissAd:(CHBDismissEvent *)event {
    [_delegate onRewardedVideoDidClose:_locationId];
}

@end
