//
//  ISUnityAdsRewardedDelegate.h
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISUnityAdsRewardedDelegate : NSObject <UADSRewardedShowDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
