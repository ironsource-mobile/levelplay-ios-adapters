//
//  ISGameloftAdapterSingleton.h
//  ISGameloftAdapter
//
//  Created by Hadar Pur on 03/08/2020.
//

#import <Foundation/Foundation.h>
#import "ISGameloftAdapter.h"
#include "GLAdsSDKWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISGameloftDelegate <NSObject>

// Rewarded Video
- (void)rewardedVideoAdClickedWithInstance:(NSString *)instance;
- (void)rewardedVideoAdHasExpiredWithInstance:(NSString *)instance;
- (void)rewardedVideoAdLoadFailedWithInstance:(NSString *)instance andReason:(GLAdsSDK_AdLoadFailedReason)reason;
- (void)rewardedVideoAdRewardedWithInstance:(NSString *)instance;
- (void)rewardedVideoAdShowFailedWithInstance:(NSString *)instance andReason:(GLAdsSDK_AdShowFailedReason)reason;
- (void)rewardedVideoAdWasClosedWithInstance:(NSString *)instance;
- (void)rewardedVideoAdWasLoadedWithInstance:(NSString *)instance;
- (void)rewardedVideoAdWillShowWithInstance:(NSString *)instance;

// Interstitital
- (void)interstitialAdClickedWithInstance:(NSString *)instance;
- (void)interstitialAdHasExpiredWithInstance:(NSString *)instance;
- (void)interstitialAdLoadFailedWithInstance:(NSString *)instance andReason:(GLAdsSDK_AdLoadFailedReason)reason;
- (void)interstitialAdShowFailedWithInstance:(NSString *)instance andReason:(GLAdsSDK_AdShowFailedReason)reason;
- (void)interstitialAdWasClosedWithInstance:(NSString *)instance;
- (void)interstitialAdWasLoadedWithInstance:(NSString *)instance;
- (void)interstitialAdWillShowWithInstance:(NSString *)instance;

// Banner
- (void)bannerAdClickedWithInstance:(NSString *)instance;
- (void)bannerAdHasExpiredWithInstance:(NSString *)instance;
- (void)bannerAdLoadFailedWithInstance:(NSString *)instance andReason:(GLAdsSDK_AdLoadFailedReason)reason;
- (void)bannerAdShowFailedWithInstance:(NSString *)instance andReason:(GLAdsSDK_AdShowFailedReason)reason;
- (void)bannerAdWasClosedWithInstance:(NSString *)instance;
- (void)bannerAdWasLoadedWithInstance:(NSString *)instance;
- (void)bannerAdWillShowWithInstance:(NSString *)instance;


@end

@interface ISGameloftAdapterSingleton : NSObject <GLAdsSDKDelegate>

+(ISGameloftAdapterSingleton* _Nonnull) sharedInstance;
-(instancetype _Nonnull)init;
-(void)addRewardedVideoDelegate:(id<ISGameloftDelegate> _Nonnull)adapterDelegate forInstanceId:(NSString* _Nonnull)instanceId;
-(void)addInterstitialDelegate:(id<ISGameloftDelegate> _Nonnull)adapterDelegate forInstanceId:(NSString* _Nonnull)instanceId;
-(void)addBannerDelegate:(id<ISGameloftDelegate> _Nonnull)adapterDelegate forInstanceId:(NSString* _Nonnull)instanceId;
-(void)reportUnknownInstanceIdFromMethod:(NSString *)method withInstanceId:(NSString *)instanceId;

@end

NS_ASSUME_NONNULL_END
