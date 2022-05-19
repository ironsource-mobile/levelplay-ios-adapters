//
//  ISYahooRewardedVideoListener.h
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>

@protocol ISYahooRewardedVideoDelegateWrapper <NSObject>
- (void)onRewardedVideoLoadSuccess:(VASInterstitialAdFactory *)interstitialAdFactory interstitialAd:(VASInterstitialAd *)interstitialAd;
- (void)onRewardedVideoLoadFail:(VASInterstitialAdFactory *)interstitialAdFactory withError: (VASErrorInfo*) errorInfo;
- (void)onRewardedVideoAdShown:(VASInterstitialAd *)interstitialAd;
- (void)onRewardedVideoShowFailed:(VASInterstitialAd *)interstitialAd withError: (VASErrorInfo*)errorInfo;
- (void)onRewardedVideoAdClicked:(VASInterstitialAd *)interstitialAd;
- (void)onRewardedVideoAdReceiveReward:(VASInterstitialAd *)interstitialAd;
- (void)onRewardedVideoAdClosed:(VASInterstitialAd *)interstitialAd;
@end

@interface ISYahooRewardedVideoListener : NSObject<VASInterstitialAdFactoryDelegate, VASInterstitialAdDelegate>

@property (nonatomic, weak) id<ISYahooRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithDelegate:(id<ISYahooRewardedVideoDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end

