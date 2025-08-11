//
//  ISVerveBannerDelegate.h
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <HyBid/HyBid.h>

@interface ISVerveBannerDelegate : NSObject <HyBidAdViewDelegate>

@property (nonatomic, strong) NSString* zoneId;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithZoneId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate;
@end
