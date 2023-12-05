//
//  ISAdMobNativeBannerDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISAdMobNativeBannerTemplate.h"

@interface ISAdMobNativeBannerDelegate : NSObject <GADNativeAdLoaderDelegate,GADAdLoaderDelegate,GADNativeAdDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, strong) ISAdMobNativeBannerTemplate* nativeTemplate;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                  nativeTemplate:(ISAdMobNativeBannerTemplate*)nativeTemplate
                        delegate:(id<ISBannerAdapterDelegate>)delegate;

@end
