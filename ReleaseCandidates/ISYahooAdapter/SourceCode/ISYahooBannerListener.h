//
//  ISYahooBannerViewListener.h
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VerizonAdsInlinePlacement/VerizonAdsInlinePlacement.h>

@protocol ISYahooBannerDelegateWrapper <NSObject>
- (void)onBannerAdLoaded:(VASInlineAdFactory *)inlineFactory inlineAdFactory: (VASInlineAdView*) inlineAdView;
- (void)onBannerLoadFailed:(VASInlineAdFactory *)inlineFactory withError: (VASErrorInfo*) errorInfo;
- (void)onBannerDidShow:(VASInlineAdView*) inlineAdView;
- (void)onBannerClicked:(VASInlineAdView *)inlineAdView;
- (void)onBannerDidLeaveApplication:(VASInlineAdView *)inlineAdView;
- (void)onBannerAdExpended:(VASInlineAdView *)inlineAdView;
- (void)onBannerAdCollapse:(VASInlineAdView *)inlineAdView;
- (UIViewController*)onBannerPresenting;


@end

@interface ISYahooBannerListener : NSObject <VASInlineAdFactoryDelegate, VASInlineAdViewDelegate>
@property (nonatomic, weak) id<ISYahooBannerDelegateWrapper> delegate;

- (instancetype)initWithDelegate:(id<ISYahooBannerDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end

