//
//  ISPubMaticInterstitialDelegate.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenWrapSDK/OpenWrapSDK.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISPubMaticInterstitialAdapter.h"

@interface ISPubMaticInterstitialDelegate : NSObject <POBInterstitialDelegate>

@property (nonatomic, strong)   NSString                             *adUnitId;
@property (nonatomic, weak)     id<ISInterstitialAdapterDelegate>    delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
