//
//  ISOguryInterstitialDelegate.h
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@protocol ISInterstitialAdDelegate;

@interface ISOguryInterstitialDelegate : NSObject <OguryInterstitialAdDelegate>

@property (nonatomic, weak) id<ISInterstitialAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate;

@end
