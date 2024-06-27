//
//  ISMolocoAdapter.m
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISMolocoAdapter.h"
#import "ISMolocoConstants.h"
#import "ISMolocoRewardedVideoAdapter.h"
#import "ISMolocoInterstitialAdapter.h"
#import "ISMolocoBannerAdapter.h"
#import <MolocoSDK/MolocoSDK-Swift.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISMolocoAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISMolocoAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return MolocoAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return Moloco.shared.sdkVersion ;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISMolocoRewardedVideoAdapter *rewardedVideoAdapter = [[ISMolocoRewardedVideoAdapter alloc] initWithMolocoAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISMolocoInterstitialAdapter *interstitialAdapter = [[ISMolocoInterstitialAdapter alloc] initWithMolocoAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        //Banner
        ISMolocoBannerAdapter *bannerAdapter = [[ISMolocoBannerAdapter alloc] initWithMolocoAdapter:self];
        [self setBannerAdapter:bannerAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithAppKey:(NSString *)appKey {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"appKey = %@", appKey);
        
        initState = INIT_STATE_IN_PROGRESS;
        MolocoInitParams *initParams = [[MolocoInitParams alloc] initWithAppKey:appKey
                                                                       mediator:MolocoMediationInfoLevelPlay];
        ISMolocoAdapter * __weak weakSelf = self;
        [[Moloco shared] initializeWithInitParams:initParams 
                                       completion:^(BOOL success, NSError * _Nullable error){
            typeof(self) strongSelf = weakSelf;
            if (success) {
                [strongSelf initializationSuccess];
            } else {
                [strongSelf initializationFailure];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackFailed:@"Moloco SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    // This is an array of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
        
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];
        
        if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                               flag:kMetaDataCOPPAKey
                                           andValue:value]) {
            [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
        }
    }
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent? @"YES" : @"NO");
    MolocoPrivacySettings.hasUserConsent = true;
}


- (void)setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    MolocoPrivacySettings.isDoNotSell = value;
    
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    MolocoPrivacySettings.isAgeRestrictedUser = value;
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {

    if (initState != INIT_STATE_SUCCESS) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't finished successfully"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    
    [Moloco.shared getBidTokenWithCompletion:^(NSString *token, NSError *error) {

        if (error) {
            LogAdapterApi_Internal(@"%@", error.localizedDescription);
            [delegate failureWithError:error.localizedDescription];
            return;
        }
        
        NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: token, @"token", nil];
        NSString *returnedToken = token? token : @"";
        LogAdapterApi_Internal(@"token = %@", returnedToken);
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
