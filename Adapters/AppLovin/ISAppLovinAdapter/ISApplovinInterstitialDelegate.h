//
//  ISApplovinInterstitialDelegate.h
//  ISApplovinInterstitialDelegate
//
//  Copyright © 2022 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLovinSDK/AppLovinSDK.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISApplovinInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidLoad:(nonnull NSString *)zoneId
                       adView:(ALAd *)adView;

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)zoneId
                          errorCode:(int)code;

- (void)onInterstitialDidOpen:(nonnull NSString *)zoneId;

- (void)onInterstitialDidClick:(nonnull NSString *)zoneId;

- (void)onInterstitialDidClose:(nonnull NSString *)zoneId;


@end

@interface ISApplovinInterstitialDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate>

@property (nonatomic, strong) NSString* zoneId;
@property (nonatomic, weak) id<ISApplovinInterstitialDelegateWrapper> delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                      delegate:(id<ISApplovinInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
