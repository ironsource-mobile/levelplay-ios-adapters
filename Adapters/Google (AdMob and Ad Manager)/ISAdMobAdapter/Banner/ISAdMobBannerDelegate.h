//
//  ISAdMobBannerDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@protocol ISBannerAdDelegate;

@interface ISAdMobBannerDelegate : NSObject <GADBannerViewDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
