//
//  ISAdMobRvFullScreenListener.h
//  ISAdMobAdapter
//
//  Created by maoz.elbaz on 24/02/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "IronSource/ISBaseAdapter+Internal.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdMobRvFullScreenDelegateWrapper <NSObject>

- (void)rvAdDidRecordImpressionForPlacementId:(nonnull NSString *)placementId;

- (void)rvAdDidFailToPresentFullScreenContentWithError:(nonnull NSError *)error ForPlacementId:(nonnull NSString *)placementId;

- (void)rvAdDidPresentFullScreenContentForPlacementId:(nonnull NSString *)placementId;

- (void)rvAdWillDismissFullScreenContentForPlacementId:(nonnull NSString *)placementId;

- (void)rvAdDidDismissFullScreenContentForPlacementId:(nonnull NSString *)placementId;

- (void)rvAdDidRecordClickForPlacementId:(nonnull NSString *)placementId;


@end

@interface ISAdMobRvFullScreenListener : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISAdMobRvFullScreenDelegateWrapper> delegate;


- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISAdMobRvFullScreenDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
