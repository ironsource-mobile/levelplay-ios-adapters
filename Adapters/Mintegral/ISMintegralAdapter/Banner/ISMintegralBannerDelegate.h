//
//  ISMintegralBannerDelegate.h
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>

@protocol ISBannerAdDelegate;

@interface ISMintegralBannerDelegate : NSObject <MTGBannerAdViewDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
