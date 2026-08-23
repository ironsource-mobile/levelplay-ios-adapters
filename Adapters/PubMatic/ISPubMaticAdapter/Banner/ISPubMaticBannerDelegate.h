//
//  ISPubMaticBannerDelegate.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenWrapSDK/OpenWrapSDK.h>

@protocol ISBannerAdDelegate;

@interface ISPubMaticBannerDelegate : NSObject <POBBannerViewDelegate>

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISBannerAdDelegate>)delegate;

@end
