//
//  ISAdMobNativeAdViewBinder.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ISAdMobNativeAdViewBinder : ISAdapterNativeAdViewBinder

- (instancetype)initWithNativeAd:(GADNativeAd *)nativeAd;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
