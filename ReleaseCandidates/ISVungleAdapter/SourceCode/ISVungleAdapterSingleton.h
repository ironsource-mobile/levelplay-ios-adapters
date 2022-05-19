//
//  ISVungleAdapterSingleton.h
//  ISVungleAdapter
//
//  Created by Bar David on 18/05/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISVungleAdapter.h"
#import <VungleSDKHeaderBidding.h>

@protocol VungleDelegate <NSObject>

// Rewarded Video
-(void)rewardedVideoPlayabilityUpdate:(BOOL)isAdPlayable
                          placementID:(NSString *)placementID
                           serverData:(NSString *)serverData
                                error:(NSError *)error;
-(void)rewardedVideoDidCloseAdWithPlacementID:(NSString *)placementID
                                   serverData:(NSString *)serverData;
-(void)rewardedVideoDidClickForPlacementID:(NSString *)placementID
                                serverData:(NSString *)serverData;
-(void)rewardedVideoDidRewardedAdWithPlacementID:(NSString *)placementID
                                      serverData:(NSString *)serverData;
-(void)rewardedVideoAdViewedForPlacement:(NSString *)placementID
                              serverData:(NSString *)serverData;

// Interstitial
-(void)interstitialPlayabilityUpdate:(BOOL)isAdPlayable
                         placementID:(NSString *)placementID
                          serverData:(NSString *)serverData
                               error:(NSError *)error;
-(void)interstitialDidCloseAdWithPlacementID:(NSString *)placementID
                                  serverData:(NSString *)serverData;
-(void)interstitialDidClickForPlacementID:(NSString *)placementID
                               serverData:(NSString *)serverData;
-(void)interstitialVideoAdViewedForPlacement:(NSString *)placementID
                                  serverData:(NSString *)serverData;

// Banner
-(void)bannerPlayabilityUpdate:(BOOL)isAdPlayable
                   placementID:(NSString *)placementID
                    serverData:(NSString *)serverData
                         error:(NSError *)error;
-(void)bannerDidCloseAdWithPlacementID:(NSString *)placementID
                            serverData:(NSString *)serverData;
-(void)bannerDidClickForPlacementID:(NSString *)placementID
                         serverData:(NSString *)serverData;
-(void)bannerWillAdLeaveApplicationForPlacementID:(NSString *)placementID
                                       serverData:(NSString *)serverData;
-(void)bannerAdViewedForPlacement:(NSString *)placementID
                       serverData:(NSString *)serverData;

@end

@interface ISVungleAdapterSingleton : NSObject <VungleSDKHBDelegate>

+(ISVungleAdapterSingleton *) sharedInstance;
-(instancetype)init;
-(void)addFirstInitiatorDelegate:(id<ISNetworkInitCallbackProtocol>)initDelegate;
-(void)addRewardedVideoDelegate:(id<VungleDelegate>)adapterDelegate
                         forKey:(NSString *)key;
-(void)addInterstitialDelegate:(id<VungleDelegate>)adapterDelegate
                forPlacementID:(NSString *)placementID;
-(void)addBannerDelegate:(id<VungleDelegate>)adapterDelegate
          forPlacementID:(NSString *)placementID;

@end

@protocol InitiatorDelegate <NSObject>

-(void)initSuccess;
-(void)initFailedWithError:(NSError *) error;

@end

