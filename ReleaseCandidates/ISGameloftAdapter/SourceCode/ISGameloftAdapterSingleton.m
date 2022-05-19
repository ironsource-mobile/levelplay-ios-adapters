//
//  ISGameloftAdapterSingleton.m
//  ISGameloftAdapterSingleton
//
//  Created by Hadar Pur on 03/08/2020.
//

#import "ISGameloftAdapterSingleton.h"

@interface ISGameloftAdapterSingleton()

@property(nonatomic) ConcurrentMutableDictionary *rewardedVideoDelegates;
@property(nonatomic) ConcurrentMutableDictionary *interstitialDelegates;
@property(nonatomic) ConcurrentMutableDictionary *bannerDelegates;

@end

@implementation ISGameloftAdapterSingleton

# pragma mark - Singleton

+(ISGameloftAdapterSingleton*) sharedInstance {
    static ISGameloftAdapterSingleton * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ISGameloftAdapterSingleton alloc] init];
    });
    return sharedInstance;
}

-(instancetype) init {
    if(self = [super init]) {
        self.rewardedVideoDelegates = [ConcurrentMutableDictionary dictionary];
        self.interstitialDelegates = [ConcurrentMutableDictionary dictionary];
        self.bannerDelegates = [ConcurrentMutableDictionary dictionary];
    }
    return self;
}

# pragma mark - Delegate registration

- (void)addRewardedVideoDelegate:(id<ISGameloftDelegate>)adapterDelegate forInstanceId:(NSString *)instanceId {
    [self.rewardedVideoDelegates setObject:adapterDelegate forKey:instanceId];
}

- (void)addInterstitialDelegate:(id<ISGameloftDelegate>)adapterDelegate forInstanceId:(NSString *)instanceId {
    [self.interstitialDelegates setObject:adapterDelegate forKey:instanceId];
}

-(void)addBannerDelegate:(id<ISGameloftDelegate>)adapterDelegate forInstanceId:(NSString *)instanceId {
    [self.bannerDelegates setObject:adapterDelegate forKey:instanceId];
}

# pragma mark - Gameloft Delegate Methods

- (void)AdWasLoaded:(GLAdsSDK_AdType)adType instance:(NSString *)instance {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@", adType, instance);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdWasLoadedWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Interstitial) {
        id<ISGameloftDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:instance];
        if (interstitialDelegate) {
            [interstitialDelegate interstitialAdWasLoadedWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Banner) {
        id<ISGameloftDelegate> bannerDelegate = [self.bannerDelegates objectForKey:instance];
        if (bannerDelegate) {
            [bannerDelegate bannerAdWasLoadedWithInstance:instance];
        }
    }
}
- (void)AdLoadFailed:(GLAdsSDK_AdType)adType instance:(NSString *)instance reason:(GLAdsSDK_AdLoadFailedReason)reason {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@, error = %u", adType, instance, reason);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdLoadFailedWithInstance:instance andReason:reason];
        }
    } else if (adType == GLAdsSDK_AdType_Interstitial) {
        id<ISGameloftDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:instance];
        if (interstitialDelegate) {
            [interstitialDelegate interstitialAdLoadFailedWithInstance:instance andReason:reason];
        }
    } else if (adType == GLAdsSDK_AdType_Banner) {
        id<ISGameloftDelegate> bannerDelegate = [self.bannerDelegates objectForKey:instance];
        if (bannerDelegate) {
            [bannerDelegate bannerAdLoadFailedWithInstance:instance andReason:reason];
        }
    }
}

- (void)AdRewarded:(GLAdsSDK_AdType)adType instance:(NSString *)instance {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@", adType, instance);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdRewardedWithInstance:instance];
        }
    }
}

- (void)AdWillShow:(GLAdsSDK_AdType)adType instance:(NSString *)instance {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@", adType, instance);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdWillShowWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Interstitial) {
        id<ISGameloftDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:instance];
        if (interstitialDelegate) {
            [interstitialDelegate interstitialAdWillShowWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Banner) {
        id<ISGameloftDelegate> bannerDelegate = [self.bannerDelegates objectForKey:instance];
        if (bannerDelegate) {
            [bannerDelegate bannerAdWillShowWithInstance:instance];
        }
    }
}

- (void)AdShowFailed:(GLAdsSDK_AdType)adType instance:(NSString *)instance reason:(GLAdsSDK_AdShowFailedReason)reason {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@, error = %u", adType, instance, reason);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdShowFailedWithInstance:instance andReason:reason];
        }
    } else if (adType == GLAdsSDK_AdType_Interstitial) {
        id<ISGameloftDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:instance];
        if (interstitialDelegate) {
            [interstitialDelegate interstitialAdShowFailedWithInstance:instance andReason:reason];
        }
    } else if (adType == GLAdsSDK_AdType_Banner) {
        id<ISGameloftDelegate> bannerDelegate = [self.bannerDelegates objectForKey:instance];
        if (bannerDelegate) {
            [bannerDelegate bannerAdShowFailedWithInstance:instance andReason:reason];
        }
    }
}


- (void)AdClicked:(GLAdsSDK_AdType)adType instance:(NSString *)instance {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@", adType, instance);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdClickedWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Interstitial) {
        id<ISGameloftDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:instance];
        if (interstitialDelegate) {
            [interstitialDelegate interstitialAdClickedWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Banner) {
        id<ISGameloftDelegate> bannerDelegate = [self.bannerDelegates objectForKey:instance];
        if (bannerDelegate) {
            [bannerDelegate bannerAdClickedWithInstance:instance];
        }
    }
}

- (void)AdWasClosed:(GLAdsSDK_AdType)adType instance:(NSString *)instance {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@", adType, instance);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdWasClosedWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Interstitial) {
        id<ISGameloftDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:instance];
        if (interstitialDelegate) {
            [interstitialDelegate interstitialAdWasClosedWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Banner) {
        id<ISGameloftDelegate> bannerDelegate = [self.bannerDelegates objectForKey:instance];
        if (bannerDelegate) {
            [bannerDelegate bannerAdWasClosedWithInstance:instance];
        }
    }
}

- (void)AdHasExpired:(GLAdsSDK_AdType)adType instance:(NSString *)instance {
    LogAdapterDelegate_Internal(@"adType = %u, instanceId = %@", adType, instance);
    
    if (!instance) {
        LogApi_Error(@"unknown instanceId: %@", instance);
        return;
    }
    
    if (adType == GLAdsSDK_AdType_Incentivized) {
        id<ISGameloftDelegate> rewardedVideoDelegate = [self.rewardedVideoDelegates objectForKey:instance];
        if (rewardedVideoDelegate) {
            [rewardedVideoDelegate rewardedVideoAdHasExpiredWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Interstitial) {
        id<ISGameloftDelegate> interstitialDelegate = [self.interstitialDelegates objectForKey:instance];
        if (interstitialDelegate) {
            [interstitialDelegate interstitialAdHasExpiredWithInstance:instance];
        }
    } else if (adType == GLAdsSDK_AdType_Banner) {
        id<ISGameloftDelegate> bannerDelegate = [self.bannerDelegates objectForKey:instance];
        if (bannerDelegate) {
            [bannerDelegate bannerAdHasExpiredWithInstance:instance];
        }
    }
}

@end
