//
//  ISPangleRewardedVideoDelegate.h
//  ISPangleAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISPangleRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidLoad:(nonnull NSString *)slotId;

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)slotId
                           withError:(nonnull NSError *)error;

- (void)onRewardedVideoDidOpen:(nonnull NSString *)slotId;

- (void)onRewardedVideoDidClick:(nonnull NSString *)slotId;

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)slotId;

- (void)onRewardedVideoDidEnd:(nonnull NSString *)slotId;

- (void)onRewardedVideoDidClose:(nonnull NSString *)slotId;

@end

@interface ISPangleRewardedVideoDelegate : NSObject<PAGRewardedAdDelegate>

@property (nonatomic, strong) NSString *slotId;
@property (nonatomic, weak) id<ISPangleRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithSlotId:(NSString *)slotId
                   andDelegate:(id<ISPangleRewardedVideoDelegateWrapper>)delegate;
@end

NS_ASSUME_NONNULL_END

