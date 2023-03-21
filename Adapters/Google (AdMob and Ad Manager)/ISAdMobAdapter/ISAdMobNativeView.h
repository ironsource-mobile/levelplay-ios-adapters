//
//  ISAdMobNativeView.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ISAdMobNativeViewLayout.h>

@interface ISAdMobNativeView : UIView
    
- (nonnull GADNativeAdView *) getNativeAdView;
- (instancetype _Nonnull) initWithLayout:(nonnull ISAdMobNativeViewLayout *)layout
                                nativeAd:(nonnull GADNativeAd *)nativeAd;

@end
