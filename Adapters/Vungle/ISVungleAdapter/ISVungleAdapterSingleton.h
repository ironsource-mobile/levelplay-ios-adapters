//
//  ISVungleAdapterSingleton.h
//  ISVungleAdapter
//
//  Created by Bar David on 18/05/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISVungleAdapter.h"
#import <vng_ios_sdk/vng_ios_sdk.h>

@protocol VungleDelegate <NSObject>

// Rewarded Video
-(void)rewardedVideoPlayabilityUpdate:(BOOL)isAdPlayable
                          placementID:(NSString *)placementID
                           serverData:(NSString *)serverData
                                error:(NSError *)error;
-(void)rewardedVideoDidClickForPlacementID:(NSString *)placementID
                                serverData:(NSString *)serverData;
-(void)rewardedVideoDidRewardedAdWithPlacementID:(NSString *)placementID
                                      serverData:(NSString *)serverData;
-(void)rewardedVideoAdViewedForPlacement:(NSString *)placementID
                              serverData:(NSString *)serverData;
-(void)rewardedVideoDidCloseAdWithPlacementID:(NSString *)placementID
                                   serverData:(NSString *)serverData;
-(void)rewardedVideoDidFailToPresentForPlacement:(NSString *)placementID
                                       withError:(NSError * _Nonnull)error;

// Interstitial
-(void)interstitialPlayabilityUpdate:(BOOL)isAdPlayable
                         placementID:(NSString *)placementID
                          serverData:(NSString *)serverData
                               error:(NSError *)error;
-(void)interstitialDidClickForPlacementID:(NSString *)placementID
                               serverData:(NSString *)serverData;
-(void)interstitialVideoAdViewedForPlacement:(NSString *)placementID
                                  serverData:(NSString *)serverData;
-(void)interstitialDidCloseAdWithPlacementID:(NSString *)placementID
                                  serverData:(NSString *)serverData;
-(void)interstitialDidFailToPresentForPlacement:(NSString *)placementID
                                      withError:(NSError * _Nonnull)error;

// Banner
-(void)bannerPlayabilityUpdate:(BOOL)isAdPlayable
                   placementID:(NSString *)placementID
                    serverData:(NSString *)serverData
                         error:(NSError *)error;
-(void)bannerDidClickForPlacementID:(NSString *)placementID
                         serverData:(NSString *)serverData;
-(void)bannerWillAdLeaveApplicationForPlacementID:(NSString *)placementID
                                       serverData:(NSString *)serverData;
-(void)bannerAdViewedForPlacement:(NSString *)placementID
                       serverData:(NSString *)serverData;
-(void)bannerDidCloseAdWithPlacementID:(NSString *)placementID
                            serverData:(NSString *)serverData;
-(void)bannerDidFailToPresentForPlacement:(NSString *)placementID
                                withError:(NSError * _Nonnull)error;

@end

@interface ISVungleAdapterSingleton : NSObject <VungleInterstitialDelegate, VungleRewardedDelegate, VungleBannerDelegate>

+(ISVungleAdapterSingleton *) sharedInstance;

-(instancetype)init;
-(void)addFirstInitiatorDelegate:(id<ISNetworkInitCallbackProtocol>)initDelegate;
-(void)addRewardedVideoDelegate:(id<VungleDelegate>)adapterDelegate
                 forPlacementID:(NSString *)placementID;
-(void)addInterstitialDelegate:(id<VungleDelegate>)adapterDelegate
                forPlacementID:(NSString *)placementID;
-(void)addBannerDelegate:(id<VungleDelegate>)adapterDelegate
          forPlacementID:(NSString *)placementID;

@end

@protocol InitiatorDelegate <NSObject>

-(void)initSuccess;
-(void)initFailedWithError:(NSError *) error;

@end

