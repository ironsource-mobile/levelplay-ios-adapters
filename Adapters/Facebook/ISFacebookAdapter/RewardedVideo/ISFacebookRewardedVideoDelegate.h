//
//  ISFacebookRewardedVideoDelegate.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISBaseAdapter+Internal.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISFacebookRewardedVideoDelegate : NSObject <FBRewardedVideoAdDelegate>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
