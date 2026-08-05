//
//  ISChartboostBannerDelegate.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ChartboostSDK/ChartboostSDK.h>

@protocol ISBannerAdDelegate;

@interface ISChartboostBannerDelegate : NSObject <CHBBannerDelegate>

@property (nonatomic, strong) CHBBanner *bannerView;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISBannerAdDelegate>)delegate;

@end
