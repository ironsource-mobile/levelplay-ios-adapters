//
//  ISAdMobNativeAdViewBinder.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <ISAdMobNativeAdViewBinder.h>

@interface ISAdMobNativeAdViewBinder()

@property (nonatomic, strong) GADNativeAd  *nativeAd;
@property (nonatomic, strong) GADNativeAdView  *admobNativeAdView;

@end

@implementation ISAdMobNativeAdViewBinder

@synthesize networkNativeAdView;

- (instancetype)initWithNativeAd:(GADNativeAd *)nativeAd {
    self = [super init];
    if (self) {
        _nativeAd = nativeAd;
        _admobNativeAdView = nil;
    }
    return self;
}

- (void)setNativeAdView:(UIView *)nativeAdView {
    if (nativeAdView == nil) {
        LogInternal_Error(@"nativeAdView is nil");
        return;
    }

    self.admobNativeAdView = [[GADNativeAdView alloc] init];

    ISNativeAdViewHolder *nativeAdViewHolder = self.adViewHolder;
    
    [self.admobNativeAdView setHeadlineView:nativeAdViewHolder.titleView];
    [self.admobNativeAdView setAdvertiserView:nativeAdViewHolder.advertiserView];
    [self.admobNativeAdView setIconView:nativeAdViewHolder.iconView];
    [self.admobNativeAdView setBodyView:nativeAdViewHolder.bodyView];
    
    LevelPlayMediaView *levelPlayMediaView = nativeAdViewHolder.mediaView;
    if (levelPlayMediaView) {
        GADMediaView *adMobMediaView = [[GADMediaView alloc] init];
        [levelPlayMediaView addSubviewAndAdjust:adMobMediaView];
        [self.admobNativeAdView setMediaView:adMobMediaView];
    }
    
    [self.admobNativeAdView setCallToActionView:nativeAdViewHolder.callToActionView];
    [self.admobNativeAdView setNativeAd:self.nativeAd];
}
 
- (UIView *)networkNativeAdView {
    return self.admobNativeAdView;
}

@end
