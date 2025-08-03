//
//  ISChartboostBannerDelegate.m
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <ISChartboostBannerDelegate.h>

@implementation ISChartboostBannerDelegate

- (instancetype)initWithLocationId:(NSString *)locationId
                       andDelegate:(id<ISChartboostBannerDelegateWrapper>)delegate {
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
        [_delegate onBannerDidFailToLoad:_locationId
                               withError:error];
    } else {
        [_delegate onBannerDidLoad:_locationId];
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
        [_delegate onBannerDidFailToShow:_locationId
                               withError:error];
    }
}

/*!
 @brief Called after an ad has recorded an impression.
 @param event An impression event with info related to the visible ad.
 @discussion Implement to be notified of when an ad has recorded an impression.
 This method will be called once a valid impression is recorded after showing the ad.
*/
- (void)didRecordImpression:(CHBImpressionEvent *)event {
    [_delegate onBannerDidRecordImpression:_locationId];
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
    [_delegate onBannerDidClick:_locationId
                      withError:error];
}

/*!
 @brief Called when a loaded ad has expired.
 @param event An expiration event with info related to the expired ad.
 @discussion Implement to be notified of when an ad has expired. This method will be called if a loaded as is not shown before a predetermined expiration interval. After expired a new ad may be loaded.
 */
- (void)didExpireAd:(CHBExpirationEvent *)event {
    [_delegate onBannerDidExpire:_locationId];
}

@end
