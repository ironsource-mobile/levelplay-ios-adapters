//
//  ISVoodooInterstitialDelegate.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VoodooAdn/VoodooAdn.h>

@protocol ISInterstitialAdDelegate;

@interface ISVoodooInterstitialDelegate : NSObject <AdnFullscreenAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
