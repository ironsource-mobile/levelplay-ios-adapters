//
//  ISYahooInterstitialDelegate.h
//  ISYahooAdapter
//
//  Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
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

