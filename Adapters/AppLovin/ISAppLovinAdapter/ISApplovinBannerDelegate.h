//
//  ISApplovinBannerDelegate.h
//  ISApplovinBannerDelegate
//
//  Copyright © 2022 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLovinSDK/AppLovinSDK.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISApplovinBannerDelegateWrapper <NSObject>

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

@interface ISApplovinBannerDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

@property (nonatomic, strong) NSString* zoneId;
@property (nonatomic, weak) id<ISApplovinBannerDelegateWrapper> delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                      delegate:(id<ISApplovinBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
