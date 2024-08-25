//
//  ISFacebookNativeAdViewBinder.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import "ISFacebookNativeAdViewBinder.h"

@interface ISFacebookNativeAdViewBinder()

@property (nonatomic, assign) ISAdOptionsPosition adOptionsPosition;
@property (nonatomic, strong) FBNativeAd          *nativeAd;
@property (nonatomic, strong) UIViewController    *viewController;

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
        LogInternal_Error(@"nativeAdView is nill");
        return;
    }
    
    ISNativeAdViewHolder *nativeAdViewHolder = self.adViewHolder;
    
    NSMutableArray *clickableViews = [[NSMutableArray alloc] init];
    if (nativeAdViewHolder.titleView) {
        [clickableViews addObject: nativeAdViewHolder.titleView];
        nativeAdViewHolder.titleView.userInteractionEnabled = YES;
    }
    if (nativeAdViewHolder.advertiserView) {
        [clickableViews addObject: nativeAdViewHolder.advertiserView];
    }
    
    if (nativeAdViewHolder.bodyView) {
        [clickableViews addObject: nativeAdViewHolder.bodyView];
    }
    if (nativeAdViewHolder.callToActionView) {
        [clickableViews addObject: nativeAdViewHolder.callToActionView];
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
    // Disable autoresizing mask translation to use Auto Layout
    adOptionsView.translatesAutoresizingMaskIntoConstraints = NO;

    // Add adOptionsView to nativeAdView
    [nativeAdView addSubview:adOptionsView];
    
    // Helper method to set constraints
    [self setAdOptionsViewConstraints:adOptionsView
                         nativeAdView:nativeAdView
                                width:FBAdOptionsViewWidth
                               height:FBAdOptionsViewHeight];
}

- (void)setAdOptionsViewConstraints:(UIView *)adOptionsView 
                       nativeAdView:(UIView *)nativeAdView
                              width:(CGFloat)width
                             height:(CGFloat)height {
    
    // Activate layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Fixed width and height for adOptionsView
        [adOptionsView.widthAnchor constraintEqualToConstant:width],
        [adOptionsView.heightAnchor constraintEqualToConstant:height],
        
        // Position adOptionsView at the top-right corner of nativeAdView
        [adOptionsView.topAnchor constraintEqualToAnchor:nativeAdView.topAnchor constant:15],
        [adOptionsView.trailingAnchor constraintEqualToAnchor:nativeAdView.trailingAnchor]
    ]];
}

@end
