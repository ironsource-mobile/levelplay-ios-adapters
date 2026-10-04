//
//  ISAdMobNativeAdDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@protocol ISNativeAdDelegate;

@interface ISAdMobNativeAdDelegate : NSObject <GADNativeAdLoaderDelegate, GADAdLoaderDelegate, GADNativeAdDelegate>

@property (nonatomic, strong) UIViewController          *viewController;
@property (nonatomic, weak)   id<ISNativeAdDelegate>    delegate;

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISNativeAdDelegate>)delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
