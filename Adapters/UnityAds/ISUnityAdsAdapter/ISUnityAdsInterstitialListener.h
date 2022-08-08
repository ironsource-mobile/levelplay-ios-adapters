//
//  ISUnityAdsInterstitialListener.h
//  ISUnityAdsAdapter
//
//  Created by Roi Eshel on 02/11/2021.
//  Copyright © 2021 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import "ISUnityAdsAdapter.h"

@protocol ISUnityAdsInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialLoadSuccess:(NSString * _Nonnull)placementId;
- (void)onInterstitialLoadFail:(NSString * _Nonnull)placementId
                     withError:(UnityAdsLoadError)error;
- (void)onInterstitialDidShow:(NSString * _Nonnull)placementId;
- (void)onInterstitialShowFail:(NSString * _Nonnull)placementId
                     withError:(UnityAdsShowError)error
                    andMessage:(NSString * _Nonnull)errorMessage;
- (void)onInterstitialDidClick:(NSString * _Nonnull)placementId;
- (void)onInterstitialDidShowComplete:(NSString * _Nonnull)placementId
                      withFinishState:(UnityAdsShowCompletionState)state;

@end

@interface ISUnityAdsInterstitialListener : NSObject <UnityAdsLoadDelegate, UnityAdsShowDelegate>

@property (nonatomic, weak)   id<ISUnityAdsInterstitialDelegateWrapper> _Nullable delegate;
@property (nonatomic, strong) NSString * _Nonnull placementId;

- (instancetype _Nonnull) initWithPlacementId:(NSString * _Nonnull)placementId
                                  andDelegate:(id<ISUnityAdsInterstitialDelegateWrapper> _Nonnull)delegate;

@end

