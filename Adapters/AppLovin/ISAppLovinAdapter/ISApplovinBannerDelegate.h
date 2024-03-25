//
//  ISAppLovinBannerDelegate.h
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAppLovinBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull NSString *)zoneId
                 adView:(ALAd *)adView;

- (void)onBannerDidFailToLoad:(nonnull NSString *)zoneId
                    errorCode:(int)code;

- (void)onBannerDidShow:(nonnull NSString *)zoneId;

- (void)onBannerDidClick:(nonnull NSString *)zoneId;

- (void)onBannerWillLeaveApplication:(nonnull NSString *)zoneId;

- (void)onBannerDidPresentFullscreen:(nonnull NSString *)zoneId;

- (void)onBannerDidDismissFullscreen:(nonnull NSString *)zoneId;

@end

@interface ISAppLovinBannerDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

@property (nonatomic, strong) NSString* zoneId;
@property (nonatomic, weak) id<ISAppLovinBannerDelegateWrapper> delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                      delegate:(id<ISAppLovinBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
