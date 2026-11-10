//
//  ISMobileFuseBannerDelegate.h
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileFuseSDK/MobileFuse.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>

@protocol ISBannerAdDelegate;

@interface ISMobileFuseBannerDelegate : NSObject <IMFAdCallbackReceiver>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
