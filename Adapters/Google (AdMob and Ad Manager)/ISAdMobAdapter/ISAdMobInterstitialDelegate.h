//
//  ISAdMobInterstitialDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdMobInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidOpen:(nonnull NSString *)adUnitId;

- (void)onInterstitialShowFail:(nonnull NSString *)adUnitId
                     withError:(nonnull NSError *)error;

- (void)onInterstitialDidClick:(nonnull NSString *)adUnitId;

- (void)onInterstitialDidClose:(nonnull NSString *)adUnitId;


@end

@interface ISAdMobInterstitialDelegate : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISAdMobInterstitialDelegateWrapper> delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISAdMobInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
