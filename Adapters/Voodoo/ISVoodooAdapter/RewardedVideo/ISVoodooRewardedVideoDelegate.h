//
//  ISVoodooRewardedVideoDelegate.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VoodooAdn/VoodooAdn.h>
#import <IronSource/ISBaseAdapter+Internal.h>

@interface ISVoodooRewardedVideoDelegate : NSObject<AdnFullscreenAdDelegate>

@property (nonatomic, strong) NSString                         *placementId;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

- (void)handleOnLoad:(NSError *)error;

@end
