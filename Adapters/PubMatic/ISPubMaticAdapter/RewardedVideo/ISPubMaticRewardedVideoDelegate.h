//
//  ISPubMaticRewardedVideoDelegate.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenWrapSDK/OpenWrapSDK.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISPubMaticRewardedVideoAdapter.h"

@interface ISPubMaticRewardedVideoDelegate : NSObject <POBRewardedAdDelegate>

@property (nonatomic, strong)   NSString                             *adUnitId;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>   delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                        andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
