//
//  ISMolocoInterstitialDelegate.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MolocoSDK/MolocoSDK-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISMolocoInterstitialAdapter.h"

@interface ISMolocoInterstitialDelegate : NSObject <MolocoInterstitialDelegate>

@property (nonatomic, strong)   NSString                            *adUnitId;
@property (nonatomic, weak)     id<ISInterstitialAdapterDelegate>   delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
