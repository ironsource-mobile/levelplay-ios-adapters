//
//  ISVungleAdapterSingleton.m
//  ISVungleAdapter
//
//  Created by Bar David on 18/05/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import "ISVungleAdapterSingleton.h"

@interface ISVungleAdapterSingleton()

@property(nonatomic) NSMapTable<NSString *, id<VungleDelegate>> *rewardedVideoDelegates;
@property(nonatomic) NSMapTable<NSString *, id<VungleDelegate>> *interstitialDelegates;
@property(nonatomic) NSMapTable<NSString *, id<VungleDelegate>> *bannerDelegates;
@property(nonatomic,weak) id<InitiatorDelegate> initiatorDelegate;

@end

@implementation ISVungleAdapterSingleton

+(ISVungleAdapterSingleton *) sharedInstance {
    static ISVungleAdapterSingleton * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ISVungleAdapterSingleton alloc] init];
    });
    
    return sharedInstance;
}

-(instancetype) init {
    if (self = [super init]) {
        _rewardedVideoDelegates =  [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                         valueOptions:NSPointerFunctionsWeakMemory];
        _interstitialDelegates  =  [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                         valueOptions:NSPointerFunctionsWeakMemory];
        _bannerDelegates        =  [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                         valueOptions:NSPointerFunctionsWeakMemory];
    }
    
    return self;
}

#pragma mark - Delegate setter

- (void)addFirstInitiatorDelegate:(id<InitiatorDelegate>)initDelegate {
    _initiatorDelegate = initDelegate;
}

- (void)addRewardedVideoDelegate:(id<VungleDelegate>)adapterDelegate
                  forPlacementID:(NSString *)placementID {
    @synchronized(_rewardedVideoDelegates) {
        [_rewardedVideoDelegates setObject:adapterDelegate
                                    forKey:placementID];
    }
}

- (void)addInterstitialDelegate:(id<VungleDelegate>)adapterDelegate
                 forPlacementID:(NSString *)placementID {
    @synchronized(_interstitialDelegates) {
        [_interstitialDelegates setObject:adapterDelegate
                                   forKey:placementID];
    }
}

- (void)addBannerDelegate:(id<VungleDelegate>)adapterDelegate
           forPlacementID:(NSString *)placementID {
    @synchronized(_bannerDelegates) {
        [_bannerDelegates setObject:adapterDelegate
                             forKey:placementID];
    }
}

#pragma mark - Delegate getter

- (id<VungleDelegate>)getRewardedVideoDelegateForPlacementID:(NSString *)placementID {
    id<VungleDelegate> delegate = nil;
    
    @synchronized(_rewardedVideoDelegates) {
        delegate = [_rewardedVideoDelegates objectForKey:key];
    }
    
    return delegate;
}

- (id<VungleDelegate>)getInterstitialDelegateForPlacementID:(NSString *)placementID {
    id<VungleDelegate> delegate = nil;
    
    @synchronized(_interstitialDelegates) {
        delegate = [_interstitialDelegates objectForKey:placementID];
    }
    
    return delegate;
}

- (id<VungleDelegate>)getBannerDelegateForPlacementID:(NSString *)placementID {
    id<VungleDelegate> delegate = nil;
    
    @synchronized(_bannerDelegates) {
        delegate = [_bannerDelegates objectForKey:placementID];
    }
    
    return delegate;
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(VungleInterstitial * _Nonnull)interstitial
{
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:interstitial.placementId];
    [interstitialDelegate interstitialPlayabilityUpdate:YES
                                            placementID:interstitial.placementId
                                             serverData:nil
                                                  error:nil];
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial * _Nonnull)interstitial withError:(NSError * _Nonnull)error {
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:interstitial.placementId];
    [interstitialDelegate interstitialPlayabilityUpdate:NO
                                            placementID:interstitial.placementId
                                             serverData:nil
                                                  error:error];
}

- (void)interstitialAdDidTrackImpression:(VungleInterstitial * _Nonnull)interstitial {
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:interstitial.placementId];
    [interstitialDelegate interstitialVideoAdViewedForPlacement:placementID
                                                     serverData:nil];
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial * _Nonnull)interstitial withError:(NSError * _Nonnull)error {
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:interstitial.placementId];
    [interstitialDelegate interstitialDidFailToPresentForPlacement:placementID
                                                         withError:error];
}

- (void)interstitialAdDidClose:(VungleInterstitial * _Nonnull)interstitial {
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:interstitial.placementId];
    [interstitialDelegate interstitialDidCloseAdWithPlacementID:placementID
                                                     serverData:nil];
}

- (void)interstitialAdDidClick:(VungleInterstitial * _Nonnull)interstitial {
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:interstitial.placementId];
    [interstitialDelegate interstitialDidClickForPlacementID:placementID
                                                  serverData:nil];
}

#pragma mark - VungleRewardedDelegate

- (void)rewardedAdDidLoad:(VungleRewarded * _Nonnull)rewarded {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForPlacementID:rewarded.placementId];
    [rewardedVideoDelegate rewardedVideoPlayabilityUpdate:YES
                                              placementID:rewarded.placementId
                                               serverData:nil
                                                    error:nil];
}

- (void)rewardedAdDidFailToLoad:(VungleRewarded * _Nonnull)rewarded withError:(NSError * _Nonnull)error {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForPlacementID:rewarded.placementId];
    [rewardedVideoDelegate rewardedVideoPlayabilityUpdate:NO
                                              placementID:rewarded.placementId
                                               serverData:nil
                                                    error:error];
}

- (void)rewardedAdDidTrackImpression:(VungleRewarded * _Nonnull)rewarded {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForPlacementID:rewarded.placementId];
    [rewardedVideoDelegate rewardedVideoAdViewedForPlacement:rewarded.placementId
                                                  serverData:nil];
}

- (void)rewardedAdDidFailToPresent:(VungleRewarded * _Nonnull)rewarded withError:(NSError * _Nonnull)error {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForPlacementID:rewarded.placementId];
    [rewardedVideoDelegate rewardedVideoDidFailToPresentForPlacement:rewarded.placementId
                                                           withError:error];
}

- (void)rewardedAdDidClose:(VungleRewarded * _Nonnull)rewarded {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForPlacementID:rewarded.placementId];
    [rewardedVideoDelegate rewardedVideoDidCloseAdWithPlacementID:rewarded.placementId
                                                       serverData:nil];
}

- (void)rewardedAdDidClick:(VungleRewarded * _Nonnull)rewarded {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForPlacementID:rewarded.placementId];
    [rewardedVideoDelegate rewardedVideoDidClickForPlacementID:rewarded.placementId
                                                    serverData:nil];
}

- (void)rewardedAdDidRewardUser:(VungleRewarded * _Nonnull)rewarded {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForPlacementID:rewarded.placementId];
    [rewardedVideoDelegate rewardedVideoDidRewardedAdWithPlacementID:rewarded.placementId
}

#pragma mark - VungleBannerDelegate

- (void)bannerAdDidLoad:(VungleBanner * _Nonnull)banner {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:banner.placementId];
    [bannerDelegate bannerPlayabilityUpdate:YES
                                placementID:banner.placementId
                                 serverData:nil
                                      error:nil];
}

- (void)bannerAdDidFailToLoad:(VungleBanner * _Nonnull)banner withError:(NSError * _Nonnull)error {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:banner.placementId];
    [bannerDelegate bannerPlayabilityUpdate:NO
                                placementID:banner.placementId
                                 serverData:nil
                                      error:error];
}

- (void)bannerAdDidTrackImpression:(VungleBanner * _Nonnull)banner {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:banner.placementId];
    [bannerDelegate bannerAdViewedForPlacement:banner.placementId
                                    serverData:nil];
}

- (void)bannerAdDidFailToPresent:(VungleBanner * _Nonnull)banner withError:(NSError * _Nonnull)error {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:banner.placementId];
    [bannerDelegate bannerDidFailToPresentForPlacement:banner.placementId
                                             withError:error];
}

- (void)bannerAdDidClose:(VungleBanner * _Nonnull)banner {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:banner.placementId];
    [bannerDelegate bannerDidCloseAdWithPlacementID:banner.placementId
                                         serverData:nil];
}

- (void)bannerAdDidClick:(VungleBanner * _Nonnull)banner {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:banner.placementId];
    [bannerDelegate bannerDidClickForPlacementID:placementID
                                      serverData:nil];
}

- (void)bannerAdWillLeaveApplication:(VungleBanner * _Nonnull)banner {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:banner.placementId];
    [bannerDelegate bannerWillAdLeaveApplicationForPlacementID:placementID
                                                    serverData:nil];
}

@end
