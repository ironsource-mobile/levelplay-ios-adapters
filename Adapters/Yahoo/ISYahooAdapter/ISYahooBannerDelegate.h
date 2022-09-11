//
//  ISYahooBannerDelegate.h
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YahooAds/YahooAds.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISYahooBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull NSString *)placementId
           withBannerAd:(nonnull YASInlineAdView *)bannerAd;
- (void)onBannerDidFailToLoad:(nonnull NSString *)placementId
                    withError:(nonnull YASErrorInfo *)errorInfo;
- (void)onBannerDidShow:(nonnull NSString *)placementId;
- (void)onBannerDidClick:(nonnull NSString *)placementId;
- (void)onBannerBannerDidLeaveApplication:(nonnull NSString *)placementId;
- (void)onBannerDidPresentScreen:(nonnull NSString *)placementId;
- (void)onBannerDidDismissScreen:(nonnull NSString *)placementId;
- (UIViewController *)bannerPresentingViewController;

@end

@interface ISYahooBannerDelegate : NSObject <YASInlineAdViewDelegate>

@property (nonatomic, strong) NSString *placementId;
@property (nonatomic, weak) id<ISYahooBannerDelegateWrapper> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISYahooBannerDelegateWrapper>)delegate;

NS_ASSUME_NONNULL_END

@end

