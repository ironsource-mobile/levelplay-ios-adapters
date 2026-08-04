//
//  ISOguryRewardedDelegate.h
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISOguryRewardedDelegate : NSObject <OguryRewardedAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
