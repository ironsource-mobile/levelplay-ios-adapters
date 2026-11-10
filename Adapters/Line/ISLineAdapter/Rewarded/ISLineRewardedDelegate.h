//
//  ISLineRewardedDelegate.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FiveAd/FiveAd.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISLineRewardedDelegate : NSObject <FADVideoRewardEventListener>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
