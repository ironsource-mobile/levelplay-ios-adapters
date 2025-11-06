//
//  ISLineInterstitialDelegate.h
//  ISLineAdapter
//
//  Copyright © 2025 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <FiveAd/FiveAd.h>
#import "ISLineInterstitialAdapter.h"

@interface ISLineInterstitialDelegate : NSObject <FADInterstitialEventListener>

@property (nonatomic, strong) NSString                            *slotId;
@property (nonatomic, weak)   ISLineInterstitialAdapter           *adapter;
@property (nonatomic, weak)   id<ISInterstitialAdapterDelegate>   delegate;

- (instancetype)initWithSlotId:(NSString *)slotId
                       adapter:(ISLineInterstitialAdapter *)adapter
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end
