//
//  ISUnityAdsBannerListener.h
//  ISUnityAdsAdapter
//
//  Created by Roi Eshel on 02/11/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import "ISUnityAdsAdapter.h"

@protocol ISUnityAdsBannerDelegateWrapper <NSObject>

- (void)onBannerLoadSuccess:(UADSBannerView * _Nonnull)bannerView;
- (void)onBannerLoadFail:(UADSBannerView * _Nonnull)bannerView
               withError:(UADSBannerError * _Nullable)error;
- (void)onBannerDidClick:(UADSBannerView * _Nonnull)bannerView;
- (void)onBannerWillLeaveApplication:(UADSBannerView * _Nonnull)bannerView;

@end

@interface ISUnityAdsBannerListener : NSObject <UADSBannerViewDelegate>

@property (nonatomic, weak) id<ISUnityAdsBannerDelegateWrapper> _Nullable delegate;

- (instancetype _Nonnull) initWithDelegate:(id<ISUnityAdsBannerDelegateWrapper> _Nonnull)delegate;

@end

