//
//  ISAdMobNativeAdData.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISAdapterNativeAdData.h>

@interface ISAdMobNativeAdData : ISAdapterNativeAdData

@property (nonatomic, strong) GADNativeAd *nativeAd;

- (instancetype)initWithNativeAd:(GADNativeAd *)nativeAd;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
