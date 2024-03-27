//
//  ISUnityAdsInterstitialDelegate.h
//  ISUnityAdsAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import <ISUnityAdsAdapter.h>

@protocol ISUnityAdsInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidLoad:(NSString * _Nonnull)placementId;
- (void)onInterstitialDidFailToLoad:(NSString * _Nonnull)placementId
                          withError:(UnityAdsLoadError)error;
- (void)onInterstitialDidOpen:(NSString * _Nonnull)placementId;
- (void)onInterstitialShowFail:(NSString * _Nonnull)placementId
                     withError:(UnityAdsShowError)error
                    andMessage:(NSString * _Nonnull)errorMessage;
- (void)onInterstitialDidClick:(NSString * _Nonnull)placementId;
- (void)onInterstitialDidShowComplete:(NSString * _Nonnull)placementId
                      withFinishState:(UnityAdsShowCompletionState)state;

@end

@interface ISUnityAdsInterstitialDelegate : NSObject <UnityAdsLoadDelegate, UnityAdsShowDelegate>

@property (nonatomic, weak)   id<ISUnityAdsInterstitialDelegateWrapper> _Nullable delegate;
@property (nonatomic, strong) NSString * _Nonnull placementId;

- (instancetype _Nonnull) initWithPlacementId:(NSString * _Nonnull)placementId
                                  andDelegate:(id<ISUnityAdsInterstitialDelegateWrapper> _Nonnull)delegate;

@end

