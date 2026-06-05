//
//  ISYandexRewardedDelegate.h
//  IronSourceYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YandexMobileAds;

@protocol ISRewardedVideoAdDelegate;

@interface ISYandexRewardedDelegate : NSObject <YMARewardedAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
