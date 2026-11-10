//
//  ISSmaatoBannerDelegate.h
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SmaatoSDKBanner/SmaatoSDKBanner.h>

@protocol ISBannerAdDelegate;

@interface ISSmaatoBannerDelegate : NSObject <SMABannerViewDelegate>

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISBannerAdDelegate>)delegate;

@end
