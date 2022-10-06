//
//  ISUnityAdsBannerListener.h
//  ISUnityAdsAdapter
//
//  Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import "ISUnityAdsAdapter.h"

@protocol ISUnityAdsBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(UADSBannerView * _Nonnull)bannerView;
- (void)onBannerDidFailToLoad:(UADSBannerView * _Nonnull)bannerView
                    withError:(UADSBannerError * _Nullable)error;
- (void)onBannerDidClick:(UADSBannerView * _Nonnull)bannerView;
- (void)onBannerWillLeaveApplication:(UADSBannerView * _Nonnull)bannerView;

@end

@interface ISUnityAdsBannerListener : NSObject <UADSBannerViewDelegate>

@property (nonatomic, weak) id<ISUnityAdsBannerDelegateWrapper> _Nullable delegate;

- (instancetype _Nonnull) initWithDelegate:(id<ISUnityAdsBannerDelegateWrapper> _Nonnull)delegate;

@end

