//
//  ISAdMobNativeAdViewBinder.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISAdapterNativeAdViewBinder.h>

@interface ISAdMobNativeAdViewBinder : ISAdapterNativeAdViewBinder

- (instancetype)initWithNativeAd:(GADNativeAd *)nativeAd;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
