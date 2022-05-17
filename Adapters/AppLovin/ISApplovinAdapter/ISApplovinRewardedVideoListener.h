//
//  ISApplovinRewardedVideoListener.h
//  ISApplovinAdapter
//
//  Created by Dor Alon on 16/09/2018.
//  Copyright © 2018 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLovinSDK/AppLovinSDK.h"

@protocol ISApplovinRewardedVideoListenerDelegate <NSObject>

- (void)onRewardedVideoDidLoad:(NSString *)zoneId;

- (void)onRewardedVideoDidFailToLoadWithError:(int)code
                                       zoneId:(NSString *)zoneId;

- (void)onRewardedVideoDidOpen:(UIView *)view
                        zoneId:(NSString *)zoneId;

- (void)onRewardedVideoDidClose:(UIView *)view
                         zoneId:(NSString *)zoneId;

- (void)onRewardedVideoDidClick:(UIView *)view
                         zoneId:(NSString *)zoneId;

- (void)onRewardedVideoDidStart:(NSString *)zoneId;

- (void)onRewardedVideoDidEnd:(NSString *)zoneId
             didReceiveReward:(BOOL)didReceiveReward;
@end

@interface ISApplovinRewardedVideoListener : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdRewardDelegate, ALAdVideoPlaybackDelegate>

@property (nonatomic, strong) NSString                          *zoneId;
@property (nonatomic, weak) id<ISApplovinRewardedVideoListenerDelegate>    delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                   andDelegate:(id<ISApplovinRewardedVideoListenerDelegate>)delegate;
- (instancetype)init NS_UNAVAILABLE;

@end
