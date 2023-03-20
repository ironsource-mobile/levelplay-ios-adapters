//
//  ISYahooBannerDelegate.m
//  ISYahooAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISYahooBannerDelegate.h>

static NSString * const kVASAdapterAdImpressionEventId = @"adImpression";

@implementation ISYahooBannerDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISYahooBannerDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark YASInlineAdViewDelegate Delegates

/**
 Called when the YASInlineAdView has been successfully fetched and its content loaded
 in preparation for display. Note that this method is only called when ad fetching
 and loading is performed via the asynchronous -[YASInlineAdView loadWithPlacementConfig:]
 method.
 
 @param inlineAd    The YASInlineAdView that was loaded.
 */
- (void)inlineAdDidLoad:(nonnull YASInlineAdView *)inlineAd {
    [_delegate onBannerDidLoad:_placementId
                  withBannerAd:inlineAd];
}

/**
 Called when an error occurs during the YASInlineAdView fetch and load lifecycle.
 A YASErrorInfo object provides detail about the error. Note that this method is only
 called when ad fetching and loading is performed via the asynchronous
 -[YASInlineAdView loadWithPlacementConfig:] method.
 
 @param inlineAd          The YASInlineAdView that experienced the error.
 @param errorInfo         The YASErrorInfo that describes the error that occurred.
 */
- (void)inlineAdLoadDidFail:(nonnull YASInlineAdView *)inlineAd
                  withError:(nonnull YASErrorInfo *)errorInfo {
    [_delegate onBannerDidFailToLoad:_placementId
                           withError:errorInfo];
}

/**
 This callback is used to surface additional events to the publisher from the SDK.
 
 @param inlineAd  The YASInlineAdView that is relaying the event.
 @param eventId   The event identifier.
 @param source    The identifier of the event source.
 @param arguments A dictionary of key/value pairs of arguments related to the event.
 */
- (void)inlineAd:(nonnull YASInlineAdView *)inlineAd
           event:(nonnull NSString *)eventId
          source:(nonnull NSString *)source
       arguments:(nonnull NSDictionary<NSString *, id> *)arguments {
    if ([eventId isEqualToString:kVASAdapterAdImpressionEventId]) {
        [_delegate onBannerDidShow:_placementId];
    }
}

/**
 Called when an error occurs during the YASInlineAdView lifecycle. A YASErrorInfo object provides detail about the error.
 
 @param inlineAd    The YASInlineAdView that experienced the error.
 @param errorInfo   The YASErrorInfo that describes the error that occured.
 */
- (void)inlineAdDidFail:(nonnull YASInlineAdView *)inlineAd
              withError:(nonnull YASErrorInfo *)errorInfo {
}

/**
 Called when the YASInlineAdView has been clicked.
 
 @param inlineAd    The YASInlineAdView that was clicked.
 */
- (void)inlineAdClicked:(nonnull YASInlineAdView *)inlineAd {
    [_delegate onBannerDidClick:_placementId];
}

/**
 Called when the YASInlineAdView causes the user to leave the application. For example, tapping a YASInlineAdView may launch an external browser.
 
 @param inlineAd    The YASInlineAdView that caused the application exit.
 */
- (void)inlineAdDidLeaveApplication:(nonnull YASInlineAdView *)inlineAd {
    [_delegate onBannerBannerDidLeaveApplication:_placementId];
}

/**
 Called prior to presenting another view controller to use for displaying the fullscreen ad.
 
 Note that this method is called on the main queue.
 
 @return a UIViewController capable of presenting another view controller to use for displaying the fullscreen ad. Returning nil will result in no fullscreen ad being displayed and an error returned to the ad.
 */
- (nullable UIViewController *)inlineAdPresentingViewController {
    return [_delegate bannerPresentingViewController];
}

/**
 Called when the YASInlineAdView has been shown.
 
 @param inlineAd    The YASInlineAdView that was shown.
 */
- (void)inlineAdDidExpand:(nonnull YASInlineAdView *)inlineAd {
    [_delegate onBannerDidPresentScreen:_placementId];
}

/**
 Called when The YASInlineAdView has been closed.
 
 @param inlineAd    The YASInlineAdView that was closed.
 */
- (void)inlineAdDidCollapse:(nonnull YASInlineAdView *)inlineAd {
    [_delegate onBannerDidDismissScreen:_placementId];
}

/**
 Called after the YASInlineAdView has been refreshed.
 
 @param inlineAd    The YASInlineAdView that was refreshed.
 */
- (void)inlineAdDidRefresh:(nonnull YASInlineAdView *)inlineAd {
}

/**
 Called after the YASInlineAdView completed resizing.
 
 @param inlineAd    The YASInlineAdView that caused the application exit.
 */
- (void)inlineAdDidResize:(nonnull YASInlineAdView *)inlineAd {
}

@end
