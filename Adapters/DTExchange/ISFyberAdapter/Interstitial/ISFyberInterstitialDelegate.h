//
//  ISFyberInterstitialDelegate.h
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>

@protocol ISInterstitialAdDelegate;

@interface ISFyberInterstitialDelegate : NSObject <IAUnitDelegate, IAVideoContentDelegate, IAMRAIDContentDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;
@property (nonatomic, weak) UIViewController *viewControllerForPresentingModalView;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
