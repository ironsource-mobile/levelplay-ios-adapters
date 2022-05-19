//
//  ISLiftoffBannerListener.h
//  ISLiftoffAdapter
//
//  Created by Roi Eshel on 14/09/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LiftoffAds/LiftoffAds.h>

@protocol ISLiftoffBannerDelegateWrapper <NSObject>

- (void)onBannerLoadSuccess:(LOBanner *)bannerAd withView:(UIView *)bannerView;
- (void)onBannerLoadFail:(LOBanner *)bannerAd;
- (void)onBannerDidShow:(LOBanner *)bannerAd;
- (void)onBannerDidClick:(LOBanner *)bannerAd;
- (void)onBannerBannerWillLeaveApplication:(LOBanner *)bannerAd;
- (void)onBannerWillPresentScreen:(LOBanner *)bannerAd;
- (void)onBannerDidDismissScreen:(LOBanner *)bannerAd;

@end

@interface ISLiftoffBannerListener : NSObject <LOBannerDelegate>

@property (nonatomic, weak) id<ISLiftoffBannerDelegateWrapper> delegate;


- (instancetype)initWithDelegate:(id<ISLiftoffBannerDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end
