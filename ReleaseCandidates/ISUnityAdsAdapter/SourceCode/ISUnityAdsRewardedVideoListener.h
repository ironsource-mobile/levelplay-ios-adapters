//
//  ISUnityAdsRewardedVideoListener.h
//  ISUnityAdsAdapter
//
//  Created by Roi Eshel on 01/11/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import "ISUnityAdsAdapter.h"

@protocol ISUnityAdsRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoLoadSuccess:(NSString * _Nonnull)placementId;
- (void)onRewardedVideoLoadFail:(NSString * _Nonnull)placementId
                      withError:(UnityAdsLoadError)error;
- (void)onRewardedVideoDidShow:(NSString * _Nonnull)placementId;
- (void)onRewardedVideoDidClick:(NSString * _Nonnull)placementId;
- (void)onRewardedVideoShowFail:(NSString * _Nonnull)placementId
                      withError:(UnityAdsShowError)error andMessage:(NSString * _Nonnull)errorMessage;
- (void)onRewardedVideoDidShowComplete:(NSString * _Nonnull)placementId
                       withFinishState:(UnityAdsShowCompletionState)state;

@end

@interface ISUnityAdsRewardedVideoListener : NSObject <UnityAdsLoadDelegate, UnityAdsShowDelegate>

@property (nonatomic, weak)   id<ISUnityAdsRewardedVideoDelegateWrapper> _Nullable delegate;
@property (nonatomic, strong) NSString * _Nonnull placementId;

- (instancetype _Nonnull) initWithPlacementId:(NSString * _Nonnull)placementId
                                  andDelegate:(id<ISUnityAdsRewardedVideoDelegateWrapper> _Nonnull)delegate;
- (instancetype _Nonnull) init NS_UNAVAILABLE;

@end

