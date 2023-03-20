//
//  ISAdColonyBannerDelegate.h
//  ISAdColonyAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdColonyBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull AdColonyAdView *)bannerView
              forZoneId:(nonnull NSString *)zoneId;

- (void)onBannerDidFailToLoad:(nonnull NSString *)zoneId
                    withError:(nonnull AdColonyAdRequestError *)error;

- (void)onBannerDidShow:(nonnull NSString *)zoneId;

- (void)onBannerDidClick:(nonnull AdColonyAdView *)bannerView
               forZoneId:(nonnull NSString *)zoneId;

- (void)onBannerBannerWillLeaveApplication:(nonnull AdColonyAdView *)bannerView
                                 forZoneId:(nonnull NSString *)zoneId;

- (void)onBannerBannerWillPresentScreen:(nonnull AdColonyAdView *)bannerView
                              forZoneId:(nonnull NSString *)zoneId;

- (void)onBannerBannerDidDismissScreen:(nonnull AdColonyAdView *)bannerView
                             forZoneId:(nonnull NSString *)zoneId;

@end

@interface ISAdColonyBannerDelegate : NSObject <AdColonyAdViewDelegate>

@property (nonatomic, strong) NSString * zoneId;
@property (nonatomic, weak) id<ISAdColonyBannerDelegateWrapper> delegate;

- (instancetype) initWithZoneId:(NSString *)zoneId
                    andDelegate:(id<ISAdColonyBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
