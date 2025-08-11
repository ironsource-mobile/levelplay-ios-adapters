//
//  ISVerveBannerAdapter.h
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISVerveAdapter+Internal.h"
#if __has_include(<HyBid/HyBid-Swift.h>)
    #import <HyBid/HyBid-Swift.h>
#else
    #import "HyBid-Swift.h"
#endif


@interface ISVerveBannerAdapter : ISBaseBannerAdapter

- (instancetype)initWithVerveAdapter:(ISVerveAdapter *)adapter;

@end
