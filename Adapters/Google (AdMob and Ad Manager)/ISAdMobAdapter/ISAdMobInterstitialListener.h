//
//  ISAdMobInterstitialListener.h
//  ISAdMobAdapter
//
//  Created by maoz.elbaz on 24/02/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "IronSource/ISBaseAdapter+Internal.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdMobInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidOpen:(nonnull NSString *)adUnitId;

- (void)onInterstitialShowFail:(nonnull NSString *)adUnitId withError:(nonnull NSError *)error;

- (void)onInterstitialDidClick:(nonnull NSString *)adUnitId;

- (void)onInterstitialDidClose:(nonnull NSString *)adUnitId;


@end

@interface ISAdMobInterstitialListener : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISAdMobInterstitialDelegateWrapper> delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId andDelegate:(id<ISAdMobInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
