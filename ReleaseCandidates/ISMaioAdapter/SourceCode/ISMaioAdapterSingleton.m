//
//  ISMaioAdapterSingleton.m
//  ISMaioAdapter
//
//  Created by Yonti Makmel on 10/06/2020.
//  Copyright © 2020 ironSource. All rights reserved.
//

#import "ISMaioAdapterSingleton.h"


@interface ISMaioAdapterSingleton()

@property(nonatomic) ConcurrentMutableDictionary *rewardedVideoDelegates;
@property(nonatomic) ConcurrentMutableDictionary *interstitialDelegates;
@property(nonatomic,weak) id<ISMaioDelegate> initiatorDelegate;

@end

@implementation ISMaioAdapterSingleton

# pragma mark - Singleton

+(ISMaioAdapterSingleton*) sharedInstance {
    static ISMaioAdapterSingleton * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ISMaioAdapterSingleton alloc] init];
    });
    return sharedInstance;
}

-(instancetype) init {
    if(self = [super init]) {
        self.initiatorDelegate = nil;
        self.rewardedVideoDelegates = [ConcurrentMutableDictionary dictionary];
        self.interstitialDelegates = [ConcurrentMutableDictionary dictionary];
    }
    return self;
}

# pragma mark - Delegate registration

-(void)addFirstInitiatorDelegate:(id<ISMaioDelegate>)initDelegate {
    self.initiatorDelegate = initDelegate;
}

-(void)addRewardedVideoDelegate:(id<ISMaioDelegate>)adapterDelegate forZoneId:(NSString* _Nonnull)zoneId {
    [self.rewardedVideoDelegates setObject:adapterDelegate forKey:zoneId];
}

-(void)addInterstitialDelegate:(id<ISMaioDelegate>)adapterDelegate forZoneId:(NSString* _Nonnull)zoneId {
    [self.interstitialDelegates setObject:adapterDelegate forKey:zoneId];
}

# pragma mark - Maio Delegate Methods

- (void)maioDidInitialize {
    if(self.initiatorDelegate != nil) {
        [self.initiatorDelegate maioDidInitialize];
        self.initiatorDelegate = nil;
    }
}

- (void)maioDidChangeCanShow:(NSString *)zoneId newValue:(BOOL)newValue {
    // get delegates
    id<ISMaioDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:zoneId];
    id<ISMaioDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:zoneId];
    
    // rewarded
    if(rewardedVideoDelegate){
        [rewardedVideoDelegate maioDidChangeCanShow:zoneId newValue:newValue];
    }
    
    // interstitial
    if(interstitialDelegate){
        [interstitialDelegate maioDidChangeCanShow:zoneId newValue:newValue];
    }
}

- (void)maioWillStartAd:(NSString *)zoneId {
    // get delegates
    id<ISMaioDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:zoneId];
    id<ISMaioDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:zoneId];
    
    // rewarded
    if(rewardedVideoDelegate){
        [rewardedVideoDelegate maioWillStartAd:zoneId];
    }
    
    // interstitial
    if(interstitialDelegate){
        [interstitialDelegate maioWillStartAd:zoneId];
    }
}

- (void)maioDidFinishAd:(NSString *)zoneId playtime:(NSInteger)playtime skipped:(BOOL)skipped rewardParam:(NSString *)rewardParam {
    // get delegates
    id<ISMaioDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:zoneId];
    id<ISMaioDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:zoneId];
    
    // rewarded
    if(rewardedVideoDelegate){
        [rewardedVideoDelegate maioDidFinishAd:zoneId playtime:playtime skipped:skipped rewardParam:rewardParam];
    }
    
    // interstitial
    if(interstitialDelegate){
        [interstitialDelegate maioDidFinishAd:zoneId playtime:playtime skipped:skipped rewardParam:rewardParam];
    }
}

- (void)maioDidClickAd:(NSString *)zoneId {
    // get delegates
    id<ISMaioDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:zoneId];
    id<ISMaioDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:zoneId];
    
    // rewarded
    if(rewardedVideoDelegate){
        [rewardedVideoDelegate maioDidClickAd:zoneId];
    }
    
    // interstitial
    if(interstitialDelegate){
        [interstitialDelegate maioDidClickAd:zoneId];
    }
}

- (void)maioDidCloseAd:(NSString *)zoneId {
    // get delegates
    id<ISMaioDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:zoneId];
    id<ISMaioDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:zoneId];
    
    // rewarded
    if(rewardedVideoDelegate){
        [rewardedVideoDelegate maioDidCloseAd:zoneId];
    }
    
    // interstitial
    if(interstitialDelegate){
        [interstitialDelegate maioDidCloseAd:zoneId];
    }
}

- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason {
    
    if ([zoneId length] == 0) {
        // init failed
        if(self.initiatorDelegate != nil) {
            [self.initiatorDelegate maioDidFail:zoneId reason:reason];
            self.initiatorDelegate = nil;
        }
        
    } else {
    
        // get delegates
        id<ISMaioDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:zoneId];
        id<ISMaioDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:zoneId];
        
        // rewarded
        if(rewardedVideoDelegate){
            [rewardedVideoDelegate maioDidFail:zoneId reason:reason];
        }
        
        // interstitial
        if(interstitialDelegate){
            [interstitialDelegate maioDidFail:zoneId reason:reason];
        }
    }
}

@end
