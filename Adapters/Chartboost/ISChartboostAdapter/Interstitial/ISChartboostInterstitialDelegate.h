//
//  ISChartboostInterstitialDelegate.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ChartboostSDK/ChartboostSDK.h>

@protocol ISInterstitialAdDelegate;

@interface ISChartboostInterstitialDelegate : NSObject <CHBInterstitialDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
