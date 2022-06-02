//
//  ISAdColonyBannerListener.h
//  ISAdColonyAdapter
//
//  Created by Roi Eshel on 9/12/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>

@protocol ISAdColonyBannerDelegateWrapper <NSObject>
- (void)onBannerLoadSuccess:(AdColonyAdView * _Nonnull)bannerView forZoneId:(NSString * _Nonnull)zoneId;
- (void)onBannerLoadFail:(NSString * _Nonnull)zoneId WithError:zoneId;
- (void)onBannerDidClick:(AdColonyAdView * _Nonnull)bannerView forZoneId:(NSString * _Nonnull)zoneId;
- (void)onBannerBannerWillLeaveApplication:(AdColonyAdView * _Nonnull)bannerView forZoneId:(NSString * _Nonnull)zoneId;
- (void)onBannerBannerWillPresentScreen:(AdColonyAdView * _Nonnull)bannerView forZoneId:(NSString * _Nonnull)zoneId;
- (void)onBannerBannerDidDismissScreen:(AdColonyAdView * _Nonnull)bannerView forZoneId:(NSString * _Nonnull)zoneId;
@end

@interface ISAdColonyBannerListener : NSObject <AdColonyAdViewDelegate>

@property (nonatomic, strong) NSString * _Nonnull zoneId;
@property (nonatomic, weak) id<ISAdColonyBannerDelegateWrapper> _Nullable delegate;

- (instancetype _Nonnull) initWithZoneId:(NSString * _Nonnull)zoneId andDelegate:(id<ISAdColonyBannerDelegateWrapper> _Nonnull)delegate;

@end
