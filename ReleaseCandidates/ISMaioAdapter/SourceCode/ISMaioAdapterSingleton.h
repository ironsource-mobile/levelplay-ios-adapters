//
//  ISMaioAdapterSingleton.h
//  ISMaioAdapter
//
//  Created by Yonti Makmel on 10/06/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISMaioAdapter.h"
#import <Maio/Maio.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISMaioDelegate <NSObject>

- (void)maioDidInitialize;
- (void)maioDidChangeCanShow:(NSString *)zoneId newValue:(BOOL)newValue;
- (void)maioWillStartAd:(NSString *)zoneId;
- (void)maioDidFinishAd:(NSString *)zoneId playtime:(NSInteger)playtime skipped:(BOOL)skipped rewardParam:(NSString *)rewardParam;
- (void)maioDidClickAd:(NSString *)zoneId;
- (void)maioDidCloseAd:(NSString *)zoneId;
- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason;

@end

@interface ISMaioAdapterSingleton : NSObject <MaioDelegate>

+(ISMaioAdapterSingleton* _Nonnull) sharedInstance;
-(instancetype _Nonnull)init;
-(void)addFirstInitiatorDelegate:(id<ISMaioDelegate>)initDelegate;
-(void)addRewardedVideoDelegate:(id<ISMaioDelegate> _Nonnull)adapterDelegate forZoneId:(NSString* _Nonnull)zoneId;
-(void)addInterstitialDelegate:(id<ISMaioDelegate> _Nonnull)adapterDelegate forZoneId:(NSString* _Nonnull)zoneId;

@end

NS_ASSUME_NONNULL_END
