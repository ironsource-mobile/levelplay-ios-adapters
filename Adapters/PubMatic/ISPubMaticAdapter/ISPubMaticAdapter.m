//
//  ISPubMaticAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticAdapter.h"
#import "ISPubMaticConstants.h"
#import "ISPubMaticRewardedVideoAdapter.h"
#import "ISPubMaticInterstitialAdapter.h"
#import "ISPubMaticBannerAdapter.h"
#import <OpenWrapSDK/OpenWrapSDK.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISPubMaticAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISPubMaticAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return PubMaticAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [OpenWrapSDK version];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISPubMaticRewardedVideoAdapter *rewardedVideoAdapter = [[ISPubMaticRewardedVideoAdapter alloc] initWithPubMaticAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISPubMaticInterstitialAdapter *interstitialAdapter = [[ISPubMaticInterstitialAdapter alloc] initWithPubMaticAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        //Banner
        ISPubMaticBannerAdapter *bannerAdapter = [[ISPubMaticBannerAdapter alloc] initWithPubMaticAdapter:self];
        [self setBannerAdapter:bannerAdapter];
    }
    
    return self;
}

- (void)initSDKWithConfig:(ISAdapterConfig *)adapterConfig {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    NSString *publisherId = adapterConfig.settings[kPublisherId];
    NSNumber *profileId = adapterConfig.settings[kProfileId];
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"publisherId = %@, profileId = %@", publisherId, profileId);
        
        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [OpenWrapSDK setLogLevel:POBSDKLogLevelDebug];
        }
        
        initState = INIT_STATE_IN_PROGRESS;
        
        ISPubMaticAdapter * __weak weakSelf = self;
        OpenWrapSDKConfig *config = [[OpenWrapSDKConfig alloc] initWithPublisherId:publisherId andProfileIds:@[profileId]];
        [OpenWrapSDK initializeWithConfig:config andCompletionHandler:^(BOOL success, NSError *error) {
            typeof(self) strongSelf = weakSelf;
            if (success) {
                [strongSelf initializationSuccess];
            } else {
                [strongSelf initializationFailure:error];
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

- (void)initializationFailure:(NSError *)error {
    LogAdapterDelegate_Internal(@"error = %@", error);

    initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackFailed:@"PubMatic SDK init failed"];
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
    
    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];

    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:kMetaDataCOPPAKey
                                       andValue:formattedValue]) {
        [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    [OpenWrapSDK setCoppaEnabled:value];
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                              adFormat:(POBAdFormat)adFormat
                         adapterConfig:(ISAdapterConfig *)adapterConfig {
    if (initState != INIT_STATE_SUCCESS) {
        NSString *error = [NSString stringWithFormat:@"Init must be completed successfully before fetching a token. initState = %ld", initState];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    POBSignalConfig *signalConfig = [[POBSignalConfig alloc] initWithAdFormat:adFormat];
    
    NSString *signal = [POBSignalGenerator generateSignalForBiddingHost:POBSDKBiddingHostUnityLevelPlay andConfig:signalConfig];
    NSString *returnedToken = signal ?: @"";
    NSDictionary *biddingDataDictionary = @{kMediationTokenKey: returnedToken};
    LogAdapterApi_Internal(@"%@ = %@", kMediationTokenKey, returnedToken);
    [delegate successWithBiddingData:biddingDataDictionary];
}

@end
