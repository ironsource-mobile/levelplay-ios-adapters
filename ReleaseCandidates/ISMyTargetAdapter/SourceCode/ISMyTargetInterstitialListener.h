//
//  ISMyTargetInterstitialListener.h
//  ISMyTargetAdapter
//
//  Created by Hadar Pur on 14/07/2020.
//


#import <Foundation/Foundation.h>
#import <MyTargetSDK/MyTargetSDK.h>

@protocol ISMyTargetInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialLoadSuccess:(MTRGInterstitialAd *)interstitialAd;
- (void)onInterstitialLoadFailWithReason:(NSString *)reason interstitialAd:(MTRGInterstitialAd *)interstitialAd;
- (void)onInterstitialClicked:(MTRGInterstitialAd *)interstitialAd;
- (void)onInterstitialDisplay:(MTRGInterstitialAd *)interstitialAd;
- (void)onInterstitialClosed:(MTRGInterstitialAd *)interstitialAd;
- (void)onInterstitialCompleted:(MTRGInterstitialAd *)interstitialAd;

@end

@interface ISMyTargetInterstitialListener : NSObject <MTRGInterstitialAdDelegate>

@property (nonatomic, weak) id<ISMyTargetInterstitialDelegateWrapper> delegate;


- (instancetype)initWithDelegate:(id<ISMyTargetInterstitialDelegateWrapper>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end
