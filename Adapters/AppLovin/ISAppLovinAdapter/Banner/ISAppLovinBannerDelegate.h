//
//  ISAppLovinBannerDelegate.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>

@protocol ISBannerAdDelegate;

@interface ISAppLovinBannerDelegate : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

@property (nonatomic, weak) ALAdView *bannerView;
@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithBannerView:(ALAdView *)bannerView
                          delegate:(id<ISBannerAdDelegate>)delegate;

@end
