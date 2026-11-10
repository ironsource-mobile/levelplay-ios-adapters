//
//  ISOguryBannerDelegate.h
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@protocol ISBannerAdDelegate;

@interface ISOguryBannerDelegate : NSObject <OguryBannerAdViewDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
