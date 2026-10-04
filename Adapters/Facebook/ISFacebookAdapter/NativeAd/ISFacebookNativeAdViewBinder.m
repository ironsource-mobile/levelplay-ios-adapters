//
//  ISFacebookNativeAdViewBinder.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISFacebookNativeAdViewBinder.h"
#import "ISFacebookConstants.h"
#import <IronSource/ISNativeAdViewHolder.h>
#import <IronSource/UIView+ISNativeView.h>
#import <IronSource/ISLog.h>

@interface ISFacebookNativeAdViewBinder ()

@property (nonatomic, assign) ISAdOptionsPosition adOptionsPosition;
@property (nonatomic, strong) FBNativeAd          *nativeAd;
@property (nonatomic, strong) UIViewController     *viewController;

@end

@implementation ISFacebookNativeAdViewBinder

- (instancetype)initWithNativeAd:(FBNativeAd *)nativeAd
               adOptionsPosition:(ISAdOptionsPosition)adOptionsPosition
                  viewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        _nativeAd = nativeAd;
        _adOptionsPosition = adOptionsPosition;
        _viewController = viewController;
    }
    return self;
}

- (void)setNativeAdView:(UIView *)nativeAdView {
    if (nativeAdView == nil) {
        LogInternal_Error(logError, logNativeAdViewNil);
        return;
    }

    ISNativeAdViewHolder *nativeAdViewHolder = self.adViewHolder;

    NSMutableArray *clickableViews = [[NSMutableArray alloc] init];
    if (nativeAdViewHolder.titleView) {
        [clickableViews addObject:nativeAdViewHolder.titleView];
        nativeAdViewHolder.titleView.userInteractionEnabled = YES;
    }
    if (nativeAdViewHolder.advertiserView) {
        [clickableViews addObject:nativeAdViewHolder.advertiserView];
    }
    if (nativeAdViewHolder.bodyView) {
        [clickableViews addObject:nativeAdViewHolder.bodyView];
    }
    if (nativeAdViewHolder.callToActionView) {
        [clickableViews addObject:nativeAdViewHolder.callToActionView];
    }

    FBMediaView *facebookMediaView;
    LevelPlayMediaView *levelPlayMediaView = nativeAdViewHolder.mediaView;
    if (levelPlayMediaView) {
        facebookMediaView = [[FBMediaView alloc] init];
        facebookMediaView.translatesAutoresizingMaskIntoConstraints = NO;

        [facebookMediaView applyNaturalWidth];
        [facebookMediaView applyNaturalHeight];
        [levelPlayMediaView addSubviewAndAdjust:facebookMediaView];
        [clickableViews addObject:levelPlayMediaView];
    }

    FBMediaView *facebookIconView;
    UIImageView *levelPlayIconView = nativeAdViewHolder.iconView;
    if (levelPlayIconView) {
        facebookIconView = [[FBMediaView alloc] init];
        [levelPlayIconView addSubview:facebookIconView];
    }

    FBAdOptionsView *adOptionsView = [[FBAdOptionsView alloc] init];
    adOptionsView.nativeAd = self.nativeAd;
    adOptionsView.backgroundColor = UIColor.clearColor;
    [self activateOptionsViewConstraintsWithAdOptionsView:adOptionsView
                                             nativeAdView:nativeAdView];

    [self.nativeAd registerViewForInteraction:nativeAdView
                                    mediaView:facebookMediaView
                                     iconView:facebookIconView
                               viewController:self.viewController
                               clickableViews:clickableViews];
}

- (UIView *)networkNativeAdView {
    return nil;
}

#pragma mark - Helpers

- (void)activateOptionsViewConstraintsWithAdOptionsView:(UIView *)adOptionsView
                                           nativeAdView:(UIView *)nativeAdView {
    adOptionsView.translatesAutoresizingMaskIntoConstraints = NO;
    [nativeAdView addSubview:adOptionsView];

    [self setAdOptionsViewConstraints:adOptionsView
                         nativeAdView:nativeAdView
                                width:FBAdOptionsViewWidth
                               height:FBAdOptionsViewHeight];
}

- (void)setAdOptionsViewConstraints:(UIView *)adOptionsView
                       nativeAdView:(UIView *)nativeAdView
                              width:(CGFloat)width
                             height:(CGFloat)height {
    [NSLayoutConstraint activateConstraints:@[
        [adOptionsView.widthAnchor constraintEqualToConstant:width],
        [adOptionsView.heightAnchor constraintEqualToConstant:height],
        [adOptionsView.topAnchor constraintEqualToAnchor:nativeAdView.topAnchor constant:adOptionsViewTopMargin],
        [adOptionsView.trailingAnchor constraintEqualToAnchor:nativeAdView.trailingAnchor]
    ]];
}

@end
