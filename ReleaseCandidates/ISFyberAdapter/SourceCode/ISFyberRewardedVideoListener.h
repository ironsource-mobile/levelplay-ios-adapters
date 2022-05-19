//
//  ISFyberRewardedVideoListener.h
//  ISFyberAdapter
//
//  Created by Guy Lis on 27/08/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IASDKCore/IASDKCore.h>
#import <IASDKCore/IASDKVideo.h>
#import <IASDKCore/IASDKMRAID.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISRewardedVideoAdapterDelegate;

@protocol ISFyberRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidShow:(NSString *)spotId;
- (void)onRewardedVideoDidClick:(NSString *)spotId;
- (void)onRewardedVideoDidReceiveReward:(NSString *)spotId;
- (void)onRewardedVideoShowFailed:(NSString *)spotId
                        withError:(NSError *)error;
- (void)onRewardedVideoDidClose:(NSString *)spotId;

@end

@interface ISFyberRewardedVideoListener : NSObject <IAUnitDelegate, IAVideoContentDelegate, IAMRAIDContentDelegate>

@property (nonatomic, strong) NSString *spotId;
@property (nonatomic, weak)   id<ISFyberRewardedVideoDelegateWrapper> delegate;
@property (nonatomic, weak)   UIViewController *viewControllerForPresentingModalView;

- (instancetype)initWithSpotId:(NSString *)spotId
                   andDelegate:(id<ISFyberRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
