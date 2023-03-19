//
//  ISAppLovinInterstitialDelegate.h
//  ISAppLovinAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAppLovinInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidLoad:(nonnull NSString *)zoneId
                       adView:(ALAd *)adView;

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)zoneId
                          errorCode:(int)code;

- (void)onInterstitialDidOpen:(nonnull NSString *)zoneId;

- (void)onInterstitialDidClick:(nonnull NSString *)zoneId;

- (void)onInterstitialDidClose:(nonnull NSString *)zoneId;


@end

@interface ISAppLovinInterstitialDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate>

@property (nonatomic, strong) NSString* zoneId;
@property (nonatomic, weak) id<ISAppLovinInterstitialDelegateWrapper> delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                      delegate:(id<ISAppLovinInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
