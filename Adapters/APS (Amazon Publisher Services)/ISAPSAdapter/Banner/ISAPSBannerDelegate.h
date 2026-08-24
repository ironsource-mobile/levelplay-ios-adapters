//
//  ISAPSBannerDelegate.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@protocol ISBannerAdDelegate;

@interface ISAPSBannerDelegate : NSObject <DTBAdBannerDispatcherDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
