//
//  ISVoodooRewardedDelegate.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VoodooAdn/VoodooAdn.h>

@protocol ISRewardedVideoAdDelegate;

@interface ISVoodooRewardedDelegate : NSObject <AdnFullscreenAdDelegate>

@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> delegate;

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate;

@end
