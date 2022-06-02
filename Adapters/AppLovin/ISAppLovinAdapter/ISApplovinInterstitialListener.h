//
//  ISApplovinInterstitialListener.h
//  ISApplovinAdapter
//
//  Created by Dor Alon on 16/09/2018.
//  Copyright © 2018 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLovinSDK/AppLovinSDK.h"

@protocol ISApplovinInterstitialListenerDelegate <NSObject>

- (void)onInterstitialDidLoad:(NSString *)zoneId
                           ad:(ALAd *)ad;

- (void)onInterstitialDidFailToLoadWithError:(int)code
                                      zoneId:(NSString *)zoneId;

- (void)onInterstitialDidOpen:(UIView *)view
                       zoneId:(NSString *)zoneId;

- (void)onInterstitialDidClick:(UIView *)view
                        zoneId:(NSString *)zoneId;

- (void)onInterstitialDidClose:(UIView *)view
                        zoneId:(NSString *)zoneId;


@end

@interface ISApplovinInterstitialListener : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate>

@property (nonatomic, strong) NSString                          *zoneId;
@property (nonatomic, weak) id<ISApplovinInterstitialListenerDelegate>    delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                   andDelegate:(id<ISApplovinInterstitialListenerDelegate>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end

