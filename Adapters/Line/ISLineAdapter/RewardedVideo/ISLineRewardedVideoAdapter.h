//
//  ISLineRewardedVideoAdapter.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISLineAdapter+Internal.h"
#import "ISLineAdapter.h"
#import <FiveAd/FiveAd.h>

@interface ISLineRewardedVideoAdapter : ISBaseRewardedVideoAdapter

- (instancetype)initWithLineAdapter:(ISLineAdapter *)adapter;

@end
