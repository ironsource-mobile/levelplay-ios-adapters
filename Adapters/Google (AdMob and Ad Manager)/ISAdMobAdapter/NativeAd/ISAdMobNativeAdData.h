//
//  ISAdMobNativeAdData.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ISAdMobNativeAdData : ISAdapterNativeAdData

@property (nonatomic, strong) GADNativeAd  *nativeAd;

- (instancetype)initWithNativeAd:(GADNativeAd *)nativeAd;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
