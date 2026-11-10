//
//  ISPubMaticInterstitialDelegate.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenWrapSDK/OpenWrapSDK.h>

@protocol ISInterstitialAdDelegate;

@interface ISPubMaticInterstitialDelegate : NSObject <POBInterstitialDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
