//
//  ISVerveRewardedVideoDelegate.h
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import "ISVerveRewardedVideoAdapter.h"
#import <HyBid/HyBid.h>


@interface ISVerveRewardedVideoDelegate : NSObject <HyBidRewardedAdDelegate>

@property (nonatomic, strong)   NSString                             *zoneId;
@property (nonatomic, weak)     id<ISRewardedVideoAdapterDelegate>   delegate;

- (instancetype)initWithZoneId:(NSString *)zoneId
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
