//
//  ISBigoRewardedDelegate.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BigoADS/BigoRewardVideoAdLoader.h>

@protocol ISRewardedVideoAdDelegate;
@class ISBigoRewardedAdapter;
@class BigoRewardVideoAd;

@interface ISBigoRewardedDelegate : NSObject <BigoRewardVideoAdLoaderDelegate, BigoRewardVideoAdInteractionDelegate>

@property (nonatomic, weak) ISBigoRewardedAdapter           *adapter;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate>   delegate;

- (instancetype)initWithAdapter:(ISBigoRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
