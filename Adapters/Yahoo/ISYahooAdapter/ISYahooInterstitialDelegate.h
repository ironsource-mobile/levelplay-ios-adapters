//
//  ISYahooInterstitialDelegate.h
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.s
//

#import <Foundation/Foundation.h>
#import <YahooAds/YahooAds.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISYahooInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidLoad:(nonnull NSString *)placementId
           withInterstitialAd:(nonnull YASInterstitialAd *)interstitialAd;
- (void)onInterstitialDidFailToLoad:(nonnull NSString *)placementId
                          withError:(nonnull YASErrorInfo *)errorInfo;
- (void)onInterstitialDidOpen:(nonnull NSString *)placementId;
- (void)onInterstitialShowFail:(nonnull NSString *)placementId
                     withError:(nonnull YASErrorInfo *)errorInfo;
- (void)onInterstitialDidClick:(nonnull NSString *)placementId;
- (void)onInterstitialDidClose:(nonnull NSString *)placementId;

@end

@interface ISYahooInterstitialDelegate : NSObject<YASInterstitialAdDelegate>

@property (nonatomic, strong) NSString *placementId;
@property (nonatomic, weak) id<ISYahooInterstitialDelegateWrapper> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISYahooInterstitialDelegateWrapper>)delegate;

NS_ASSUME_NONNULL_END

@end

