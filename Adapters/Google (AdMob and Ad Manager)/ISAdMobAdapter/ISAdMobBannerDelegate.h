//
//  ISAdMobBannerDelegate.h
//  ISAdMobAdapter
//
//  Created by maoz.elbaz on 21/05/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "IronSource/ISBaseAdapter+Internal.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdMobBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull GADBannerView *)bannerView;

- (void)onBannerDidFailToLoad:(nonnull NSString *)adUnitId
                    withError:(nonnull NSError *)error;

- (void)onBannerDidShow:(nonnull NSString *)adUnitId;

- (void)onBannerDidClick:(nonnull NSString *)adUnitId;

// Click-Time Lifecycle Notifications

- (void)onBannerWillPresentScreen:(nonnull NSString *)adUnitId;

- (void)onBannerDidDismissScreen:(nonnull NSString *)adUnitId;


@end

@interface ISAdMobBannerDelegate : NSObject <GADBannerViewDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISAdMobBannerDelegateWrapper> delegate;


- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISAdMobBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
