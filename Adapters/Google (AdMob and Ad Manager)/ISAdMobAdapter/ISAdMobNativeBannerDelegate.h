//
//  ISAdMobNativeBannerDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdMobNativeBannerDelegateWrapper <NSObject>

- (void)onNativeBannerDidLoadWithAdUnitId:(nonnull NSString *)adUnitId
                                 nativeAd:(nonnull GADNativeAd *)nativeAd
                                     size:(ISBannerSize*)size;

- (void)onNativeBannerDidFailToLoadWithAdUnitId:(nonnull NSString *)adUnitId
                                          error:(nonnull NSError *)error;

- (void)onNativeBannerDidShow:(nonnull NSString *)adUnitId;

- (void)onNativeBannerDidClick:(nonnull NSString *)adUnitId;

// Click-Time Lifecycle Notifications

- (void)onNativeBannerWillPresentScreen:(nonnull NSString *)adUnitId;

- (void)onNativeBannerDidDismissScreen:(nonnull NSString *)adUnitId;


@end

@interface ISAdMobNativeBannerDelegate : NSObject <GADNativeAdLoaderDelegate,GADAdLoaderDelegate,GADNativeAdDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, strong) ISBannerSize* size;
@property (nonatomic, weak) id<ISAdMobNativeBannerDelegateWrapper> delegate;


- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                            size:(ISBannerSize*)size
                        delegate:(id<ISAdMobNativeBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
