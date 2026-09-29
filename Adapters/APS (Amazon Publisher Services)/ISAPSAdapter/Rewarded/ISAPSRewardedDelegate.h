//
//  ISAPSRewardedDelegate.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISAPSRewardedDelegate : NSObject <DTBAdInterstitialDispatcherDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;
@property (nonatomic, copy) NSString *creativeId;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate
                      creativeId:(NSString *)creativeId;

@end
