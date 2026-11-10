//
//  ISInMobiBannerDelegate.h
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>

@protocol ISBannerAdDelegate;

@interface ISInMobiBannerDelegate : NSObject <IMBannerDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
