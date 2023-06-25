//
//  ISAdMobNativeView.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ISAdMobNativeBannerTemplate.h>

@interface ISAdMobNativeView : UIView
    
- (nonnull GADNativeAdView *) getNativeAdView;
- (instancetype _Nonnull) initWithTemplate:(nonnull ISAdMobNativeBannerTemplate *)nativeTemplate
                                  nativeAd:(nonnull GADNativeAd *)nativeAd;

@end
