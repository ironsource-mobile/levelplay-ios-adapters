//
//  ISLineAdapter.m
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISLineAdapter.h"
#import "ISLineConstants.h"
#import "ISLineRewardedVideoAdapter.h"
#import "ISLineInterstitialAdapter.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

static FADAdLoader *lineAdLoader = nil;

@interface ISLineAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISLineAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return LineAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [FADSettings semanticVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISLineRewardedVideoAdapter *rewardedVideoAdapter = [[ISLineRewardedVideoAdapter alloc] initWithLineAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISLineInterstitialAdapter *interstitialAdapter = [[ISLineInterstitialAdapter alloc] initWithLineAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

- (void)initSDKWithAppId:(NSString *)appId {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE) {
        [initCallbackDelegates addObject:self];
    }
    
    if(appId == nil){
        [self initializationFailure];
        return;
    }

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"appId = %@", appId);
        FADConfig *config = [self getConfig:appId];
        [FADSettings registerConfig:config];
        
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

- (void)initializationFailure {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackFailed:@"Line SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                                 appId:(NSString *)appId
                                 slotId:(NSString *)slotId{
    if (initState != INIT_STATE_SUCCESS) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't started"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    FADAdLoader *adLoader = [self getAdLoader:appId];
    if (adLoader == nil){
        [delegate failureWithError:@"adLoader is nil - Line"];
        return;
    }
    [adLoader collectSignalWithSlotId:slotId withSignalCallback:^(NSString *_Nullable signal, NSError *_Nullable error) {
        if (error != nil){
            LogAdapterApi_Internal(@"%@", error.localizedDescription);
            [delegate failureWithError:error.localizedDescription];
            return;
        }
        if (signal.length == 0){
            [delegate failureWithError:@"Token is nil or empty - Line"];
            return;
        }
        NSDictionary *biddingDataDictionary = @{kMediationTokenKey: signal};
        LogAdapterApi_Internal(@"%@ = %@", kMediationTokenKey, signal);
        [delegate successWithBiddingData:biddingDataDictionary];
      }];
}

- (FADConfig *)getConfig:(NSString *)appId {
    FADConfig *config = [[FADConfig alloc] initWithAppId:appId];
    return config;
}

- (FADAdLoader *)getAdLoader:(NSString *)appId {
    if (!lineAdLoader) {
        NSError *error = nil;
        FADConfig *config = [self getConfig:appId];
        lineAdLoader = [FADAdLoader adLoaderForConfig:config outError:&error];
        if (error) {
            LogAdapterApi_Internal(@"Error creating line adLoader: %@", error.localizedDescription);
            lineAdLoader = nil;
        }
    }
    return lineAdLoader;
}

@end
