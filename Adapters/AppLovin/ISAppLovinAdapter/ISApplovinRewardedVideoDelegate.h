//
//  ISAppLovinRewardedVideoDelegate.h
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import "ISAppLovinAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISAppLovinRewardedVideoDelegateWrapper <NSObject>

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

@interface ISAppLovinRewardedVideoDelegate : NSObject<ALAdLoadDelegate, ALAdDisplayDelegate, ALAdRewardDelegate, ALAdVideoPlaybackDelegate>

@property (nonatomic, strong) NSString                                 *zoneId;
@property (nonatomic, weak) ISAppLovinAdapter                          *adapter;
@property (nonatomic, weak) id<ISAppLovinRewardedVideoDelegateWrapper> delegate;


- (instancetype)initWithZoneId:(NSString *)zoneId
                        adapter:(ISAppLovinAdapter*)adapter
                       delegate:(id<ISAppLovinRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
