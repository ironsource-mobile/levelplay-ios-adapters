//
//  ISFacebookRewardedVideoDelegate.h
//  ISFacebookAdapter
//
//  Created by Hadar Pur on 01/08/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISFacebookRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidLoad:(nonnull NSString *)placementID;

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)placementID
                           withError:(nullable NSError *)error;

- (void)onRewardedVideoDidOpen:(nonnull NSString *)placementID;

- (void)onRewardedVideoDidClick:(nonnull NSString *)placementID;

- (void)onRewardedVideoDidEnd:(nonnull NSString *)placementID;

- (void)onRewardedVideoDidClose:(nonnull NSString *)placementID;

@end

@interface ISFacebookRewardedVideoDelegate : NSObject <FBRewardedVideoAdDelegate>

@property (nonatomic, strong) NSString* placementID;
@property (nonatomic, weak) id<ISFacebookRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID
                        andDelegate:(id<ISFacebookRewardedVideoDelegateWrapper>)delegate;

@end


NS_ASSUME_NONNULL_END
