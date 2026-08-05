//
//  ISChartboostRewardedDelegate.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ChartboostSDK/ChartboostSDK.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISChartboostRewardedDelegate : NSObject <CHBRewardedDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
