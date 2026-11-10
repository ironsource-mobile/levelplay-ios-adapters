//
//  ISFyberBannerDelegate.h
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>

@protocol ISBannerAdDelegate;

@interface ISFyberBannerDelegate : NSObject <IAUnitDelegate, IAMRAIDContentDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;
@property (nonatomic, weak) UIViewController *viewControllerForPresentingModalView;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
