//
//  ISAdMobBannerAdapter.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISAdMobAdapter+Internal.h"

@interface ISAdMobBannerAdapter : ISBaseBannerAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter;

- (CGFloat)getAdaptiveHeightWithWidth:(CGFloat)width;
@end
