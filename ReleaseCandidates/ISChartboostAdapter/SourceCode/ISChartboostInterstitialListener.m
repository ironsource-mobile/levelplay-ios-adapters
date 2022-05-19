//
//  ISChartboostInterstitialListener.m
//  ISChartboostAdapter
//
//  Created by Hadar Pur on 12/03/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import "ISChartboostInterstitialListener.h"

@implementation ISChartboostInterstitialListener

- (instancetype)initWithPlacementId:(NSString *)locationId
                        andDelegate:(id<ISChartboostInterstitialWrapper>)delegate {
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
- (void) didCacheAd:(CHBCacheEvent *)event
              error:(CHBCacheError *)error {
    if (error) {
        [_delegate didFailToCacheInterstitial:_locationId
                                    withError:error];
    } else {
        [_delegate didCacheInterstitial:_locationId];
    }
}

/*!
 @brief Called after a showFromViewController: call, either if the ad has been presented and an ad impression logged, or if the operation failed.
 @param event A show event with info related to the ad shown.
 @param error An error specifying the failure reason, or nil if the operation was successful.
 @discussion Implement to be notified of when the ad presentation process has finished.
 This method will be called once for each call to showFromViewController: on an interstitial or rewarded ad.
 In contrast, this may be called multiple times after showing a banner, either if some error occurs after the ad has been successfully shown or as a result of the banner's automatic content refresh.
 */
- (void) didShowAd:(CHBShowEvent *)event
             error:(CHBShowError *)error {
    if (error) {
        [_delegate didFailToShowInterstitial:_locationId
                                   withError:error];
    } else {
        [_delegate didDisplayInterstitial:_locationId];
    }
}

/*!
 @brief Called after an ad has been clicked.
 @param event A click event with info related to the ad clicked.
 @param error An error specifying the failure reason, or nil if the operation was successful.
 @discussion Implement to be notified of when an ad has been clicked.
 If the click does not result into the opening of a link an error will be provided explaning why.
 */
- (void) didClickAd:(CHBClickEvent *)event
              error:(CHBClickError *)error {
    [_delegate didClickInterstitial:_locationId];
}

/*!
 @brief Called after an ad is dismissed.
 @param event A dismiss event with info related to the dismissed ad.
 @discussion Implement to be notified of when an ad is no longer displayed.
 Note that this method won't get called for ads that failed to be shown. To handle that case implement didShowAd:error:
 You may use the error property inside the event to know if the dismissal was expected or caused by an error.
 */
- (void) didDismissAd:(CHBDismissEvent *)event {
    [_delegate didDismissInterstitial:_locationId];
}

@end
