//
//  ISMolocoInterstitialDelegate.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

@protocol ISInterstitialAdDelegate;

@interface ISMolocoInterstitialDelegate : NSObject <MolocoInterstitialDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate>     delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
