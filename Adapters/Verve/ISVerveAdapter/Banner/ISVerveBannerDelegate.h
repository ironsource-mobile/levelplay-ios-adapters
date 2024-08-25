//
//  ISVerveBannerDelegate.h
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
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
