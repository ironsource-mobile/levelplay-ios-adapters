//
//  ISMolocoInterstitialDelegate.h
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
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
