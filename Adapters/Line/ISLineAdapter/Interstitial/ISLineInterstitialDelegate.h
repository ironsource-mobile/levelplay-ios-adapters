//
//  ISLineInterstitialDelegate.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FiveAd/FiveAd.h>

@protocol ISInterstitialAdDelegate;

@interface ISLineInterstitialDelegate : NSObject <FADInterstitialEventListener>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
