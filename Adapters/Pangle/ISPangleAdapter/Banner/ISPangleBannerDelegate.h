//
//  ISPangleBannerDelegate.h
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <PAGAdSDK/PAGAdSDK.h>

@protocol ISBannerAdDelegate;

@interface ISPangleBannerDelegate : NSObject <PAGBannerAdDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate>    delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
