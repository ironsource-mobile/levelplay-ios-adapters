//
//  ISPubMaticBannerDelegate.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <OpenWrapSDK/OpenWrapSDK.h>
#import "ISPubMaticAdapter.h"

@interface ISPubMaticBannerDelegate : NSObject <POBBannerViewDelegate>

@property (nonatomic, strong)   NSString                        *adUnitId;
@property (nonatomic, weak)     ISPubMaticAdapter               *adapter;
@property (nonatomic, weak)     id<ISBannerAdapterDelegate>     delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                         adapter:(ISPubMaticAdapter *)adapter
                        andDelegate:(id<ISBannerAdapterDelegate>)delegate;

@end
