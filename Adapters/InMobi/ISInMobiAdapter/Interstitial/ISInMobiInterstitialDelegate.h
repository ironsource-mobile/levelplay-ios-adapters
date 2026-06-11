//
//  ISInMobiInterstitialDelegate.h
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>

@protocol ISInterstitialAdDelegate;

@interface ISInMobiInterstitialDelegate : NSObject <IMInterstitialDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
