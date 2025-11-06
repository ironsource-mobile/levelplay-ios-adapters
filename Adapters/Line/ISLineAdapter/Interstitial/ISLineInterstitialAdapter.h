//
//  ISLineInterstitialAdapter.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISLineAdapter+Internal.h"
#import <FiveAd/FiveAd.h>
#import "ISLineAdapter.h"

@interface ISLineInterstitialAdapter : ISBaseInterstitialAdapter

- (instancetype)initWithLineAdapter:(ISLineAdapter *)adapter;

@end
