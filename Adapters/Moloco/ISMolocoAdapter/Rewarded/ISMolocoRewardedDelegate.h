//
//  ISMolocoRewardedDelegate.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISMolocoRewardedDelegate : NSObject <MolocoRewardedDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate>     delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
