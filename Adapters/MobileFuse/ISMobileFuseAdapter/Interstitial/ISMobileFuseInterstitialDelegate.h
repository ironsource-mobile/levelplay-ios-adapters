//
//  ISMobileFuseInterstitialDelegate.h
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileFuseSDK/MobileFuse.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>

@protocol ISInterstitialAdDelegate;

@interface ISMobileFuseInterstitialDelegate : NSObject <IMFAdCallbackReceiver>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
