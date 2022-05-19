//
//  ISYahooInterstitialListener.h
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.s
//

#import <Foundation/Foundation.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>

@protocol ISYahooInterstitialDelegateWrapper <NSObject>
- (void)onInterstitialLoadSuccess:(VASInterstitialAdFactory *)interstitialAdFactory InterstitialAd:(VASInterstitialAd*) interstitialAd;
- (void)onInterstitialLoadFail:(VASInterstitialAdFactory *)interstitialAdFactory withError: (VASErrorInfo*)errorInfo;
- (void)onInterstitialAdShown:(VASInterstitialAd *)interstitialAd;
- (void)onInterstitialShowFailed:(VASInterstitialAd *)interstitialAd withError: (VASErrorInfo*) errorInfo;
- (void)onInterstitialAdClicked:(VASInterstitialAd *)interstitialAd;
- (void)onInterstitialAdClosed:(VASInterstitialAd *)interstitialAd;
@end


@interface ISYahooInterstitialListener : NSObject<VASInterstitialAdFactoryDelegate, VASInterstitialAdDelegate>

@property (nonatomic, weak) id<ISYahooInterstitialDelegateWrapper> delegate;

- (instancetype)initWithDelegate:(id<ISYahooInterstitialDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end

