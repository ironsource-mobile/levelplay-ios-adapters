//
//  ISYahooBannerViewListener.m
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISYahooBannerListener.h"

static NSString * const  kVASAdapterAdImpressionEventId = @"adImpression";

@implementation ISYahooBannerListener

- (instancetype)initWithDelegate:(id<ISYahooBannerDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}
#pragma mark VASInlineAdFactoryDelegate Delegates

// Called when there is an error requesting a VASInlineAdView or loading a VASInlineAdView from the cache.
- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)InlineAdFactory didLoadInlineAd:(nonnull VASInlineAdView *)inlineAdView {
    [_delegate onBannerAdLoaded:InlineAdFactory inlineAdFactory:inlineAdView];
}

// Called when the VASInlineAdView has been loaded. A new VASInlineAdView instance will be provided as part of this callback.
- (void)inlineAdFactory:(nonnull VASInlineAdFactory *)InlineAdFactory didFailWithError:(nonnull VASErrorInfo *)errorInfo {
    [_delegate onBannerLoadFailed:InlineAdFactory withError:errorInfo];
}

#pragma mark VASInlineAdViewDelegate Delegates

// This callback is used to surface additional events to the publisher from the SDK.
- (void)inlineAd:(nonnull VASInlineAdView *)inlineAdView event:(nonnull NSString *)eventId source:(nonnull NSString *)source arguments:(nonnull NSDictionary<NSString *,id> *)arguments {
    if (eventId == kVASAdapterAdImpressionEventId) {
        [_delegate onBannerDidShow:inlineAdView];
    }
}

// Called when an error occurs during the VASInlineAdView lifecycle. A VASErrorInfo object provides detail about the error.
- (void)inlineAdDidFail:(nonnull VASInlineAdView *)inlineAdView withError:(nonnull VASErrorInfo *)errorInfo {
}

// Called when the VASInlineAdView has been clicked.
- (void)inlineAdClicked:(nonnull VASInlineAdView *)inlineAdView {
    [_delegate onBannerClicked:inlineAdView];
}

// Called when the VASInlineAdView causes the user to leave the application. For example, tapping a VASInlineAdView may launch an external browser.
- (void)inlineAdDidLeaveApplication:(nonnull VASInlineAdView *)inlineAdView {
    [_delegate onBannerDidLeaveApplication:inlineAdView];
}

// Called prior to presenting another view controller to use for displaying the fullscreen ad.
- (nullable UIViewController *)inlineAdPresentingViewController {
    return [_delegate onBannerPresenting];
}

// Called when The VASInlineAdView has been closed.
- (void)inlineAdDidCollapse:(nonnull VASInlineAdView *)inlineAdView {
    [_delegate onBannerAdCollapse:inlineAdView];
}

// Called when the VASInlineAdView has been shown.
- (void)inlineAdDidExpand:(nonnull VASInlineAdView *)inlineAdView {
    [_delegate onBannerAdExpended:inlineAdView];
}

// Called after the VASInlineAdView has been refreshed.
- (void)inlineAdDidRefresh:(nonnull VASInlineAdView *)inlineAdView {
}

// Called after the VASInlineAdView completed resizing.
- (void)inlineAdDidResize:(nonnull VASInlineAdView *)inlineAdView {
}
@end
