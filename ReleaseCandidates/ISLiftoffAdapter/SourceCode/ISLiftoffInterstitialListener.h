//
//  ISLiftoffInterstitialListener.h
//  ISLiftoffAdapter
//
//  Created by Roi Eshel on 14/09/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LiftoffAds/LiftoffAds.h>

@protocol ISLiftoffInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialLoadSuccess:(LOInterstitial *)interstitialAd;
- (void)onInterstitialLoadFail:(LOInterstitial *)interstitialAd;
- (void)onInterstitialShowFail:(LOInterstitial *)interstitialAd;
- (void)onInterstitialDidOpen:(LOInterstitial *)interstitialAd;
- (void)onInterstitialDidShow:(LOInterstitial *)interstitialAd;
- (void)onInterstitialDidClick:(LOInterstitial *)interstitialAd;
- (void)onInterstitialDidClose:(LOInterstitial *)interstitialAd;

@end

@interface ISLiftoffInterstitialListener : NSObject <LOInterstitialDelegate>

@property (nonatomic, weak) id<ISLiftoffInterstitialDelegateWrapper> delegate;


- (instancetype)initWithDelegate:(id<ISLiftoffInterstitialDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end
