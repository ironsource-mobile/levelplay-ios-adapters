//
//  ISVungleBannerDelegate.h
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

@protocol ISBannerAdDelegate;

@interface ISVungleBannerDelegate : NSObject <VungleBannerViewDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;
@property (nonatomic, assign) BOOL isAdLoadSuccess;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
