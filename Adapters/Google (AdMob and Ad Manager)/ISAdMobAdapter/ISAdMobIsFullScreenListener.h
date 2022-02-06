//
//  ISAdMobIsFullScreenListener.h
//  ISAdMobAdapter
//
//  Created by maoz.elbaz on 24/02/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "IronSource/ISBaseAdapter+Internal.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdMobIsFullScreenDelegateWrapper <NSObject>

- (void)isAdDidRecordImpressionForPlacementId:(nonnull NSString *)placementId;

- (void)isAdDidFailToPresentFullScreenContentWithError:(nonnull NSError *)error ForPlacementId:(nonnull NSString *)placementId;

- (void)isAdDidPresentFullScreenContentForPlacementId:(nonnull NSString *)placementId;

- (void)isAdWillDismissFullScreenContentForPlacementId:(nonnull NSString *)placementId;

- (void)isAdDidDismissFullScreenContentForPlacementId:(nonnull NSString *)placementId;

- (void)isAdDidRecordClickForPlacementId:(nonnull NSString *)placementId;

@end

@interface ISAdMobIsFullScreenListener : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISAdMobIsFullScreenDelegateWrapper> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISAdMobIsFullScreenDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
