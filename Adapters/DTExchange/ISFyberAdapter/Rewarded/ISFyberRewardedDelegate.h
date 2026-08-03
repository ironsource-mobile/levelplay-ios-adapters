//
//  ISFyberRewardedDelegate.h
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISFyberRewardedDelegate : NSObject <IAUnitDelegate, IAVideoContentDelegate, IAMRAIDContentDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;
@property (nonatomic, weak) UIViewController *viewControllerForPresentingModalView;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
