//
//  ISMolocoRewardedVideoDelegate.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MolocoSDK/MolocoSDK-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISMolocoRewardedVideoAdapter.h"

@interface ISMolocoRewardedVideoDelegate : NSObject <MolocoRewardedDelegate>

@property (nonatomic, strong)   NSString                             *adUnitId;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>   delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
