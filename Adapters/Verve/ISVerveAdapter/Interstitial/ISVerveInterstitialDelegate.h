//
//  ISVerveInterstitialDelegate.h
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <HyBid/HyBid.h>
#if __has_include(<HyBid/HyBid-Swift.h>)
    #import <HyBid/HyBid-Swift.h>
#else
    #import "HyBid-Swift.h"
#endif

@protocol ISInterstitialAdDelegate;

@interface ISVerveInterstitialDelegate : NSObject <HyBidInterstitialAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
