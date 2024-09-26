//
//  ISOguryAdapter.m
//  ISOguryAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//
#import "ISOguryAdapter.h"
#import "ISOguryConstants.h"
#import "ISOguryRewardedVideoAdapter.h"
#import "ISOguryInterstitialAdapter.h"
#import "ISOguryBannerAdapter.h"
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>
#import <OguryChoiceManager/OguryChoiceManager.h>
#import <OguryCore/OguryLogLevel.h>


// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISOguryAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISOguryAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return oguryAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [Ogury getSdkVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISOguryRewardedVideoAdapter *rewardedVideoAdapter = [[ISOguryRewardedVideoAdapter alloc] initWithOguryAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISOguryInterstitialAdapter *interstitialAdapter = [[ISOguryInterstitialAdapter alloc] initWithOguryAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        //Banner
        ISOguryBannerAdapter *bannerAdapter = [[ISOguryBannerAdapter alloc] initWithOguryAdapter:self];
        [self setBannerAdapter:bannerAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    
    return self;
}

- (void)initSDKWithAssetKey:(NSString *)assetKey {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"assetKey = %@", assetKey);
        
        initState = INIT_STATE_IN_PROGRESS;
        OguryConfigurationBuilder *configurationBuilder = [[OguryConfigurationBuilder alloc] initWithAssetKey:assetKey];
        
        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [Ogury setLogLevel:OguryLogLevelAll];
        }
        
        [Ogury startWithConfiguration:[configurationBuilder build]];
        [self initializationSuccess];

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
    

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    // Ogury getBidderToken results with a warning on UIThread if called from a background thread.
    // They plan to fix it on a later version
    NSString *token = [OguryTokenService getBidderToken];
    
    NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: token, @"token", nil];
    NSString *returnedToken = token? token : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    [delegate successWithBiddingData:biddingDataDictionary];
}

@end
