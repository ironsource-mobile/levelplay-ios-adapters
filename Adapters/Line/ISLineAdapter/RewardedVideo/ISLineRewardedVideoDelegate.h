//
//  ISLineRewardedVideoDelegate.h
//  ISLineAdapter
//
//  Copyright © 2025 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <FiveAd/FiveAd.h>
#import "ISLineRewardedVideoAdapter.h"

@interface ISLineRewardedVideoDelegate : NSObject <FADVideoRewardEventListener>

@property (nonatomic, strong) NSString                             *slotId;
@property (nonatomic, weak)   ISLineRewardedVideoAdapter           *adapter;
@property (nonatomic, weak)   id<ISRewardedVideoAdapterDelegate>   delegate;

- (instancetype)initWithSlotId:(NSString *)slotId
                       adapter:(ISLineRewardedVideoAdapter *)adapter
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate;

@end
