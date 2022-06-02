//
//  ISApplovinBannerListener.h
//  ISApplovinAdapter
//
//  Created by Dor Alon on 16/09/2018.
//  Copyright © 2018 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLovinSDK/AppLovinSDK.h"

@protocol ISApplovinBannerListenerDelegate <NSObject>

- (void)onBannerLoadSuccess:(ALAd *)ad
                 zoneID:(NSString *)zoneId;

- (void)onBannerLoadFail:(NSString *)zoneId
               error:(int)code;

- (void)onBannerDidShow:(UIView *)view
                 zoneID:(NSString *)zoneId;

- (void)onBannerDidClick:(NSString *)zoneId;

- (void)onBannerWillLeaveApplication:(NSString *)zoneId;

- (void)onBannerDidPresentFullscreen:(NSString *)zoneId;

- (void)onBannerDidDismissFullscreen:(NSString *)zoneId;

@end

@interface ISApplovinBannerListener : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

@property (nonatomic, strong) NSString                              *zoneId;
@property (nonatomic, weak) id<ISApplovinBannerListenerDelegate>    delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                   andDelegate:(id<ISApplovinBannerListenerDelegate>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end
