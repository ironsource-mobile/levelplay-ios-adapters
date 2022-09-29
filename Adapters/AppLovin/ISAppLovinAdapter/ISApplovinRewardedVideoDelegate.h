//
//  ISApplovinRewardedVideoDelegate.h
//  ISApplovinRewardedVideoDelegate
//
//  Copyright © 2022 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLovinSDK/AppLovinSDK.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISApplovinRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidLoad:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)zoneId
                           errorCode:(int)code;

- (void)onRewardedVideoDidOpen:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidStart:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidClick:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidClose:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidEnd:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)zoneId;
            

@end

@interface ISApplovinRewardedVideoDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdRewardDelegate, ALAdVideoPlaybackDelegate>

@property (nonatomic, strong) NSString* zoneId;
@property (nonatomic, weak) id<ISApplovinRewardedVideoDelegateWrapper> delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                      delegate:(id<ISApplovinRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
