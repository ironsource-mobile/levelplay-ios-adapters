//
//  ISUnityAdsInterstitialDelegate.h
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>

@protocol ISInterstitialAdDelegate;

@interface ISUnityAdsInterstitialDelegate : NSObject <UADSInterstitialShowDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
