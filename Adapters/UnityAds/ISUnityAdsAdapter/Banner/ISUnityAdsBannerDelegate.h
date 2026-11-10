//
//  ISUnityAdsBannerDelegate.h
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>

@protocol ISBannerAdDelegate;

@interface ISUnityAdsBannerDelegate : NSObject <UADSBannerAdDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
