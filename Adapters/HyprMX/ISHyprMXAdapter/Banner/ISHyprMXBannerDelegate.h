//
//  ISHyprMXBannerDelegate.h
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <HyprMX/HyprMX.h>

@protocol ISBannerAdDelegate;

@interface ISHyprMXBannerDelegate : NSObject <HyprMXBannerDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
