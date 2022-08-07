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
                          forKey:(NSString *)key {
    @synchronized(_rewardedVideoDelegates) {
        [_rewardedVideoDelegates setObject:adapterDelegate
                                    forKey:key];
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

- (id<VungleDelegate>)getRewardedVideoDelegateForKey:(NSString *)key {
    id<VungleDelegate> delegate;
    
    @synchronized(_rewardedVideoDelegates) {
        delegate = [_rewardedVideoDelegates objectForKey:key];
    }
    
    return delegate;
}

- (id<VungleDelegate>)getInterstitialDelegateForPlacementID:(NSString *)placementID {
    id<VungleDelegate> delegate;
    
    @synchronized(_interstitialDelegates) {
        delegate = [_interstitialDelegates objectForKey:placementID];
    }
    
    return delegate;
}

- (id<VungleDelegate>)getBannerDelegateForPlacementID:(NSString *)placementID {
    id<VungleDelegate> delegate;
    
    @synchronized(_bannerDelegates) {
        delegate = [_bannerDelegates objectForKey:placementID];
    }
    
    return delegate;
}

#pragma mark - Vungle Delegate

/**
 * If implemented, this will get called when VungleSDK has finished initialization.
 * It's only at this point that one can call `playAd:options:placementID:error`
 * and `loadPlacementWithID:` without getting initialization errors
 */
- (void)vungleSDKDidInitialize {
    if (_initiatorDelegate) {
        [_initiatorDelegate initSuccess];
    }
}

/**
 * If implemented, this will get called if the VungleSDK fails to initialize.
 * The included NSError object should give some information as to the failure reason.
 * @note If initialization fails, you will need to restart the VungleSDK.
 */
- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
    if (_initiatorDelegate) {
        [_initiatorDelegate initFailedWithError:error];
    }
}

/* This vungleAdPlayabilityUpdate callbacks will be called with isAdPlayable = NO in the following cases:
 
 SDK Initialization:
 * During init, if there are no cached ads available for immediate playback
 
 During ad load:
 * If there is an error loading an ad for a placement
 * If there is not enough available memory when loading an ad for a placement
 * If the placement is 'sleeping' when attempting to load an ad for a placement
 
 During ad playback:
 * On ad play, if the SDK finds that the ad associated with the placement has expired
 * On ad play, if the SDK will play the placement
 
 During ad dismissal:
 * On ad dismissal, if the next ad is not already cached for the associated placement
 */

/**
 * If implemented, this will get called when the SDK has an ad ready to be displayed. Also it will
 * get called with an argument `NO` for `isAdPlayable` when for some reason, there is
 * no ad available, for instance there is a corrupt ad or the OS wiped the cache.
 * Please note that receiving a `NO` here does not mean that you can't play an Ad: if you haven't
 * opted-out of our Exchange, you might be able to get a streaming ad if you call `play`.
 * @param isAdPlayable A boolean indicating if an ad is currently in a playable state
 * @param placementID The ID of a placement which is ready to be played
 * @param error The error that was encountered.  This is only sent when the placementID is nil.
 */
- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(NSString *)placementID
                            error:(NSError *)error {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:placementID];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];

    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoPlayabilityUpdate:isAdPlayable
                                                  placementID:placementID
                                                   serverData:nil
                                                        error:error];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialPlayabilityUpdate:isAdPlayable
                                                placementID:placementID
                                                 serverData:nil
                                                      error:error];
    } else if (bannerDelegate) {
        [bannerDelegate bannerPlayabilityUpdate:isAdPlayable
                                    placementID:placementID
                                     serverData:nil
                                          error:error];
    }
}

/**
 * If implemented, this will get called when the SDK has an ad ready to be displayed. Also it will
 * get called with an argument `NO` for `isAdPlayable` when for some reason, there is
 * no ad available, for instance there is a corrupt ad or the OS wiped the cache.
 * Please note that receiving a `NO` here does not mean that you can't play an Ad: if you haven't
 * opted-out of our Exchange, you might be able to get a streaming ad if you call `play`.
 * @param isAdPlayable A boolean indicating if an ad is currently in a playable state
 * @param placementID The ID of a placement which is ready to be played
 * @param adMarkup The ad markup of an adUnit which is ready to be played.
 * @param error The error that was encountered.  This is only sent when the placementID is nil.
 */
- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(NSString *)placementID
                         adMarkup:(NSString *)adMarkup
                            error:(NSError *)error {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:adMarkup];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoPlayabilityUpdate:isAdPlayable
                                                  placementID:placementID
                                                   serverData:adMarkup
                                                        error:error];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialPlayabilityUpdate:isAdPlayable
                                                placementID:placementID
                                                 serverData:adMarkup
                                                      error:error];
    } else if (bannerDelegate) {
        [bannerDelegate bannerPlayabilityUpdate:isAdPlayable
                                    placementID:placementID
                                     serverData:adMarkup
                                          error:error];
    }
}

/**
 * If implemented, this will be called when the ad is first rendered for the specified placement.
 * @NOTE: Please use this callback to track views.
 * @param placementID The placement ID of the advertisement shown
 */
- (void)vungleAdViewedForPlacement:(NSString *)placementID {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:placementID];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoAdViewedForPlacement:placementID
                                                      serverData:nil];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialVideoAdViewedForPlacement:placementID
                                                         serverData:nil];
    } else if (bannerDelegate) {
        [bannerDelegate bannerAdViewedForPlacement:placementID
                                        serverData:nil];
    }
}

/**
 * If implemented, this will be called when the ad is first rendered for the specified placement.
 * @NOTE: Please use this callback to track views.
 * @param placementID The placement ID of the advertisement shown
 * @param adMarkup The ad markup of the advertisement shown.
 */
- (void)vungleAdViewedForPlacementID:(NSString *)placementID
                            adMarkup:(NSString *)adMarkup {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:adMarkup];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoAdViewedForPlacement:placementID
                                                      serverData:adMarkup];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialVideoAdViewedForPlacement:placementID
                                                         serverData:adMarkup];
    } else if (bannerDelegate) {
        [bannerDelegate bannerAdViewedForPlacement:placementID
                                        serverData:adMarkup];
    }
}

/**
 * If implemented, this method gets called when user clicks the Vungle Ad.
 * At this point, it's recommended to track the click event.
 */
- (void)vungleTrackClickForPlacementID:(nullable NSString *)placementID {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:placementID];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoDidClickForPlacementID:placementID
                                                        serverData:nil];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialDidClickForPlacementID:placementID
                                                      serverData:nil];
    } else if (bannerDelegate) {
        [bannerDelegate bannerDidClickForPlacementID:placementID
                                          serverData:nil];
    }
}

/**
 * If implemented, this method gets called when user clicks the Vungle Ad.
 * At this point, it's recommended to track the click event.
 * @param placementID The placement ID of the advertisement shown.
 * @param adMarkup The ad markup of the advertisement shown
 */
- (void)vungleTrackClickForPlacementID:(NSString *)placementID
                              adMarkup:(NSString *)adMarkup {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:adMarkup];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoDidClickForPlacementID:placementID
                                                        serverData:adMarkup];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialDidClickForPlacementID:placementID
                                                      serverData:adMarkup];
    } else if (bannerDelegate) {
        [bannerDelegate bannerDidClickForPlacementID:placementID
                                          serverData:adMarkup];
    }
}

/**
 * If implemented, this method gets called when user taps the Vungle Ad
 * which will cause them to leave the current application(e.g. the ad action
 * opens the iTunes store, Mobile Safari, etc).
 */
- (void)vungleWillLeaveApplicationForPlacementID:(NSString *)placementID {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (bannerDelegate) {
        [bannerDelegate bannerWillAdLeaveApplicationForPlacementID:placementID
                                                        serverData:nil];
    }
}

/**
 * If implemented, this method gets called when user taps the Vungle Ad
 * which will cause them to leave the current application(e.g. the ad action
 * opens the iTunes store, Mobile Safari, etc).
 * @param placementID The placement ID of the advertisement about to leave the current application.
 * @param adMarkup The ad markup of the advertisement about to leave the current application.
 */
- (void)vungleWillLeaveApplicationForPlacementID:(NSString *)placementID
                                        adMarkup:(NSString *)adMarkup {
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (bannerDelegate) {
        [bannerDelegate bannerWillAdLeaveApplicationForPlacementID:placementID
                                                        serverData:adMarkup];
    }
}

/**
 * This method is called when the user should be rewarded for watching a Rewarded Video Ad.
 * At this point, it's recommended to reward the user.
 */
- (void)vungleRewardUserForPlacementID:(NSString *)placementID {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoDidRewardedAdWithPlacementID:placementID
                                                              serverData:nil];
    }
}

/**
 * This method is called when the user should be rewarded for watching a Rewarded Video Ad.
 * At this point, it's recommended to reward the user.
 * @param placementID The placement ID of the advertisement shown.
 * @param adMarkup The ad markup of the advertisement shown.
 */
- (void)vungleRewardUserForPlacementID:(NSString *)placementID
                              adMarkup:(NSString *)adMarkup {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:adMarkup];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoDidRewardedAdWithPlacementID:placementID
                                                              serverData:adMarkup];
    }
}

/**
 * If implemented, this will get called when the SDK is about to show an ad. This point
 * might be a good time to pause your game, and turn off any sound you might be playing.
 * @param placementID The placement which is about to be shown.
 */
- (void)vungleWillShowAdForPlacementID:(NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
}

/**
 * If implemented, this will get called when the SDK is about to show an ad. This point
 * might be a good time to pause your game, and turn off any sound you might be playing.
 * @param placementID The placement which is about to be shown.
 * @param adMarkup The ad markup of an adUnit which is about to be shown.
 */
- (void)vungleWillShowAdForPlacementID:(NSString *)placementID
                              adMarkup:(NSString *)adMarkup {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
}

/**
 * If implemented, this will get called when the SDK has presented the view controller or the
 * view that houses the ad.
 * @param placementID The placement which is about to be shown.
 */
- (void)vungleDidShowAdForPlacementID:(NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
}

/**
 * If implemented, this will get called when the SDK has presented the view controller or the
 * view that houses the ad.
 * @param placementID The placement which is about to be shown.
 * @param adMarkup The ad markup of an adUnit which is about to be shown..
 */
- (void)vungleDidShowAdForPlacementID:(NSString *)placementID
                             adMarkup:(NSString *)adMarkup {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
}

/**
 * If implemented, this method gets called when a Vungle Ad Unit is about to be completely dismissed.
 * At this point, it's recommended to resume your Game or App.
 */
- (void)vungleWillCloseAdForPlacementID:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
}

/**
 * If implemented, this method gets called when a Vungle Ad Unit is about to be completely dismissed.
 * At this point, it's recommended to resume your Game or App.
 * @param placementID The placement ID of the advertisement about to be closed.
 * @param adMarkup The ad markup of the advertisement about to be closed.
 */
- (void)vungleWillCloseAdForPlacementID:(NSString *)placementID
                               adMarkup:(NSString *)adMarkup {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
}

/**
 * If implemented, this method gets called when a Vungle Ad Unit has been completely dismissed.
 * At this point, you can load another ad for non-auto-cached placement if necessary.
 * @param placementID The placement ID of the advertisement that has been closed.
 * @param adMarkup The ad markup of the advertisement that has been closed.
 */
- (void)vungleDidCloseAdForPlacementID:(NSString *)placementID
                              adMarkup:(NSString *)adMarkup {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:adMarkup];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoDidCloseAdWithPlacementID:placementID
                                                           serverData:adMarkup];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialDidCloseAdWithPlacementID:placementID
                                                         serverData:adMarkup];
    } else if (bannerDelegate) {
        [bannerDelegate bannerDidCloseAdWithPlacementID:placementID
                                             serverData:adMarkup];
    }
}

/**
 * If implemented, this method gets called when a Vungle Ad Unit has been completely dismissed.
 * At this point, you can load another ad for non-auto-cached placement if necessary.
 */
- (void)vungleDidCloseAdForPlacementID:(nonnull NSString *)placementID {
    id<VungleDelegate> rewardedVideoDelegate = [self getRewardedVideoDelegateForKey:placementID];
    id<VungleDelegate> interstitialDelegate = [self getInterstitialDelegateForPlacementID:placementID];
    id<VungleDelegate> bannerDelegate = [self getBannerDelegateForPlacementID:placementID];
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate rewardedVideoDidCloseAdWithPlacementID:placementID
                                                           serverData:nil];
    } else if (interstitialDelegate) {
        [interstitialDelegate interstitialDidCloseAdWithPlacementID:placementID
                                                         serverData:nil];
    } else if (bannerDelegate) {
        [bannerDelegate bannerDidCloseAdWithPlacementID:placementID
                                             serverData:nil];
    }
}

@end
