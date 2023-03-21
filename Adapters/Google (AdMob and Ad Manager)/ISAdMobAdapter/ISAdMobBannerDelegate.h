//
//  ISAdMobBannerDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

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
