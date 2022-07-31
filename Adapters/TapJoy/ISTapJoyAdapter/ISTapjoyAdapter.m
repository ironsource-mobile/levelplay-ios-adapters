//
//  ISTapjoyAdapter.m
//  ISTapjoyAdapter
//
//  Created by Daniil Bystrov on 4/13/16.
//  Copyright © 2016 IronSource. All rights reserved.
//

#import "ISTapjoyAdapter.h"
#import "ISTapjoyRewardedVideoDelegate.h"
#import "ISTapjoyInterstitialDelegate.h"
#import <Tapjoy/TJPlacement.h>
#import <Tapjoy/Tapjoy.h>

// Tapjoy requires a mediation name
static NSString * const kMediationName      = @"ironsource";

// Network keys
static NSString * const kAdapterVersion     = TapjoyAdapterVersion;
static NSString * const kAdapterName        = @"Tapjoy";
static NSString * const kSdkKey             = @"sdkKey";
static NSString * const kPlacementName      = @"placementName";

// Meta data keys
static NSString * const kMetaDataCOPPAKey   = @"Tapjoy_COPPA";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// Handle init callback for all adapter instances
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState _initState = INIT_STATE_NONE;

// Tapjoy members
static TJPrivacyPolicy * _privacyPolicy;
static NSString *userId = @"";

@interface ISTapjoyAdapter () <ISTapjoyRewardedVideoDelegateWrapper, ISTapjoyInterstitialDelegateWrapper, ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoPlacementNameToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoPlacementNameToTapjoyDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoPlacementToIsReady;
@property (nonatomic, strong) ConcurrentMutableSet          *rewardedVideoPlacementNamesForInitCallbacks;
// Tapjoy Placements cannot be released from a background thread and therefore they are stored in NSMutableDictionary instead of ConcurrentMutableDictionary
@property (nonatomic, strong) NSMutableDictionary           *rewardedVideoPlacementNameToPlacement;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialPlacementNameToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialPlacementNameToTapjoyDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialPlacementToIsReady;
// Tapjoy Placements cannot be released from a background thread and therefore they are stored in NSMutableDictionary instead of ConcurrentMutableDictionary
@property (nonatomic, strong) NSMutableDictionary           *interstitialPlacementNameToPlacement;


@end

@implementation ISTapjoyAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    if (self) {
        
        if(initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoPlacementNameToSmashDelegate      = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementNameToTapjoyDelegate     = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementToIsReady                = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementNameToPlacement          = [NSMutableDictionary dictionary];
        _rewardedVideoPlacementNamesForInitCallbacks           = [ConcurrentMutableSet new];

        // Interstitial
        _interstitialPlacementNameToSmashDelegate       = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementNameToTapjoyDelegate      = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementToIsReady                 = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementNameToPlacement           = [NSMutableDictionary dictionary];

        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
        
        _privacyPolicy = [Tapjoy getPrivacyPolicy];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IronSource Protocol Methods

// get adapter version
- (NSString *)version {
    return kAdapterVersion;
}

//get network sdk version
- (NSString *)sdkVersion {
    return [Tapjoy getVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"CFNetwork", @"CoreData", @"CoreTelephony", @"SystemConfiguration", @"StoreKit", @"UIKit", @"WebKit"];
}

- (NSString *)sdkName {
    return @"Tapjoy";
}

#pragma mark - Initializations Methods And Callbacks

- (void)initSDKWithUserId:(NSString *)userId
                andSdkKey:(NSString *)sdkKey {
    
    // add self to the init delegates only in case the initialization has not finished yet
    if(_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS){
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _initState = INIT_STATE_IN_PROGRESS;
        
        [self setTapjoyInitobserves];
        
        LogAdapterApi_Internal(@"sdkKey = %@, userId = %@", sdkKey, userId);

        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [Tapjoy enableLogging:YES];
            [Tapjoy setDebugEnabled:YES];
            LogAdapterApi_Internal(@"enableLogging=YES");
        }
        
        self.userId = userId;
        
        LogAdapterApi_Internal(@"Tapjoy connect");
        [Tapjoy connect:sdkKey];
    });
}

- (void)tjcConnectSuccess:(NSNotification *)notifyObj {
    LogAdapterDelegate_Internal(@"");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TJC_CONNECT_SUCCESS
                                                  object:nil];

    _initState = INIT_STATE_SUCCESS;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate success
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)tjcConnectFail:(NSNotification *)notifyObj {
    LogAdapterDelegate_Internal(@"");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TJC_CONNECT_FAILED
                                                  object:nil];

    _initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate fail
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackFailed:@"TapJoy SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    LogInternal_Internal(@"");

    // set user id
    [self setUserId];
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementNameToSmashDelegate.allKeys;
    
    for (NSString* placementName in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];
        if ([_rewardedVideoPlacementNamesForInitCallbacks hasObject:placementName]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:placementName
                                 serverData:nil
                                   delegate:delegate];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementNameToSmashDelegate.allKeys;
    
    for (NSString *placementName in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];
        [delegate adapterInterstitialInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    LogInternal_Internal(@"");

    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementNameToSmashDelegate.allKeys;
    
    for (NSString* placementName in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];
        if ([_rewardedVideoPlacementNamesForInitCallbacks hasObject:placementName]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementNameToSmashDelegate.allKeys;
    
    for (NSString *placementName in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API

// used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString* sdkKey = adapterConfig.settings[kSdkKey];
    NSString* placementName = adapterConfig.settings[kPlacementName];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:sdkKey]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:placementName]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementName];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementName = %@", placementName);
    
    ISTapjoyRewardedVideoDelegate *rewardedVideoDelegate = [[ISTapjoyRewardedVideoDelegate alloc] initWithPlacementName:placementName
                                                                                                            andDelegate:self];

    //add to rewarded video delegate map
    [_rewardedVideoPlacementNameToSmashDelegate setObject:delegate
                                                   forKey:placementName];
    
    [_rewardedVideoPlacementNameToTapjoyDelegate setObject:rewardedVideoDelegate
                                                    forKey:placementName];
    
    [_rewardedVideoPlacementToIsReady setObject:@NO
                                         forKey:placementName];
    
    //add to rewarded video init callback map
    [_rewardedVideoPlacementNamesForInitCallbacks addObject:placementName];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithUserId:userId
                          andSdkKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementName = %@", placementName);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Tapjoy SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

// used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString* sdkKey = adapterConfig.settings[kSdkKey];
    NSString* placementName = adapterConfig.settings[kPlacementName];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:sdkKey]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:placementName]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementName];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementName = %@", placementName);
    
    ISTapjoyRewardedVideoDelegate *rewardedVideoDelegate = [[ISTapjoyRewardedVideoDelegate alloc] initWithPlacementName:placementName
                                                                                                            andDelegate:self];

    //add to rewarded video delegate map
    [_rewardedVideoPlacementNameToSmashDelegate setObject:delegate
                                                   forKey:placementName];
    
    [_rewardedVideoPlacementNameToTapjoyDelegate setObject:rewardedVideoDelegate
                                                    forKey:placementName];
    
    [_rewardedVideoPlacementToIsReady setObject:@NO
                                         forKey:placementName];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithUserId:userId
                          andSdkKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternal:placementName
                                 serverData:nil
                                   delegate:delegate];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementName = %@", placementName);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    NSString* placementName = adapterConfig.settings[kPlacementName];
    
    [self loadRewardedVideoInternal:placementName
                         serverData:serverData
                           delegate:delegate];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString* placementName = adapterConfig.settings[kPlacementName];
    
    [self loadRewardedVideoInternal:placementName
                         serverData:nil
                           delegate:delegate];
}

- (void)loadRewardedVideoInternal:(NSString *)placementName
                       serverData:(NSString *)serverData
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    LogAdapterApi_Internal(@"placementName = %@", placementName);

    TJPlacement* placement = nil;
    ISTapjoyRewardedVideoDelegate *rewardedVideoDelegate = [_rewardedVideoPlacementNameToTapjoyDelegate objectForKey:placementName];

    if (serverData.length > 0) {
        placement = [self getTJBiddingPlacement:placementName
                                     serverData:serverData
                                 tapjoyDelegate:rewardedVideoDelegate];
    } else {
        placement = [self getTJPlacement:placementName
                          tapjoyDelegate:rewardedVideoDelegate];
    }
    
    if (placement == nil) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
            
    placement.videoDelegate = rewardedVideoDelegate;
    
    [_rewardedVideoPlacementNameToPlacement setObject:placement forKey:placementName];

    [placement requestContent];
    
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* placementName = adapterConfig.settings[kPlacementName];
        LogAdapterApi_Internal(@"placementName = %@", placementName);
        
        // change rewarded video availability to false
        [delegate adapterRewardedVideoHasChangedAvailability:NO];

        if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
            TJPlacement* placement = [_rewardedVideoPlacementNameToPlacement objectForKey:placementName];
            [placement showContentWithViewController:viewController];
            
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_NO_ADS_TO_SHOW
                                             userInfo:@{NSLocalizedDescriptionKey : @"No ads to show"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
            
        }
        
        [_rewardedVideoPlacementToIsReady setObject:@NO
                                             forKey:placementName];
    });
}


- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString* placementName = adapterConfig.settings[kPlacementName];
    if ([_rewardedVideoPlacementToIsReady objectForKey:placementName] && [_rewardedVideoPlacementNameToPlacement objectForKey:placementName]) {
        return [[_rewardedVideoPlacementToIsReady objectForKey:placementName] boolValue];
    } else {
        return NO;
    }
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    
    [_rewardedVideoPlacementToIsReady setObject:@YES
                                         forKey:placementName];
    
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)placementName
                           withError:(nullable NSError *)error {
    LogAdapterDelegate_Internal(@"placementName = %@, error = %@", placementName, error);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        
        if (error) {
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        }
    }
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)onRewardedVideoShowFail:(nonnull NSString *)placementName
               withErrorMessage:(nullable NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"placementName = %@, error = %@", placementName, errorMessage);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        NSString *desc = [NSString stringWithFormat:@"Show failed for placement: %@ with reason - %@", placementName, errorMessage];
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey : desc}];

        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)onRewardedVideoDidEnd:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidReceiveReward];
        [delegate adapterRewardedVideoDidEnd];
    }
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementNameToSmashDelegate objectForKey:placementName];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClose];
    }
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self initInterstitialWithUserId:userId
                       adapterConfig:adapterConfig
                            delegate:delegate];
}

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString* sdkKey = adapterConfig.settings[kSdkKey];
    NSString* placementName = adapterConfig.settings[kPlacementName];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:sdkKey]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementName]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementName];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementName = %@", placementName);
    
    ISTapjoyInterstitialDelegate *interstitialDelegate = [[ISTapjoyInterstitialDelegate alloc] initWithPlacementName:placementName
                                                                                                         andDelegate:self];

    //add to interstitial delegate map
    [_interstitialPlacementNameToTapjoyDelegate setObject:interstitialDelegate
                                                   forKey:placementName];
    
    [_interstitialPlacementNameToSmashDelegate setObject:delegate
                                                  forKey:placementName];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithUserId:userId
                          andSdkKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementName = %@", placementName);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Tapjoy SDK init failed"}];
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementName = adapterConfig.settings[kPlacementName];
   
    [self loadInterstitialInternal:placementName
                        serverData:serverData
                          delegate:delegate];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementName = adapterConfig.settings[kPlacementName];
    
    [self loadInterstitialInternal:placementName
                        serverData:nil
                          delegate:delegate];
}

- (void)loadInterstitialInternal:(NSString *)placementName
                      serverData:(NSString *)serverData
                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"placementName = %@", placementName);

    TJPlacement* placement = nil;
    ISTapjoyInterstitialDelegate *interstitialDelegate = [_interstitialPlacementNameToTapjoyDelegate objectForKey:placementName];

    if (serverData.length > 0) {
        placement = [self getTJBiddingPlacement:placementName
                                     serverData:serverData
                                 tapjoyDelegate:interstitialDelegate];
    } else {
        placement = [self getTJPlacement:placementName
                          tapjoyDelegate:interstitialDelegate];
    }
    
    if (placement == nil) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey : @"Load error"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    placement.videoDelegate = interstitialDelegate;
    
    [_interstitialPlacementNameToPlacement setObject:placement
                                              forKey:placementName];
    
    [_interstitialPlacementToIsReady setObject:@NO
                                        forKey:placementName];
    
    [placement requestContent];
    
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString* placementName = adapterConfig.settings[kPlacementName];
        LogAdapterApi_Internal(@"placementName = %@", placementName);

        if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
            TJPlacement* placement = [_interstitialPlacementNameToPlacement objectForKey:placementName];
            [placement showContentWithViewController:viewController];
            
        } else {
            NSString *desc = [NSString stringWithFormat:@"Show interstitial failed - no ads to show"];
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_NO_ADS_TO_SHOW
                                             userInfo:@{NSLocalizedDescriptionKey : desc}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
        
        [_interstitialPlacementToIsReady setObject:@NO
                                            forKey:placementName];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString* placementName = adapterConfig.settings[kPlacementName];
    if ([_interstitialPlacementToIsReady objectForKey:placementName] && [_interstitialPlacementNameToPlacement objectForKey:placementName]) {
        return [[_interstitialPlacementToIsReady objectForKey:placementName] boolValue];
    } else {
        return NO;
    }
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialVideoDidLoad:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    
    [_interstitialPlacementToIsReady setObject:@YES
                                        forKey:placementName];
    
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)placementName
                          withError:(nullable NSError *)error {
    LogAdapterDelegate_Internal(@"placementName = %@, error = %@", placementName, error);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        
        if (!error) {
            error = [NSError errorWithDomain:kAdapterName
                                        code:ERROR_CODE_GENERIC
                                    userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: @"%@ load failed", kAdapterName]}];
        }

        [delegate adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (void)onInterstitialDidOpen:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialShowFail:(nonnull NSString *)placementName
              withErrorMessage:(nullable NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"placementName = %@, error = %@", placementName, errorMessage);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        NSString *desc = [NSString stringWithFormat:@"Show failed for placement: %@ with reason - %@", placementName, errorMessage];
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey : desc}];
        
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (void)onInterstitialDidClick:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)onInterstitialDidClose:(nonnull NSString *)placementName {
    LogAdapterDelegate_Internal(@"placementName = %@", placementName);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementNameToSmashDelegate objectForKey:placementName];

    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString* placementName = adapterConfig.settings[kPlacementName];

    if ([_rewardedVideoPlacementNameToPlacement objectForKey:placementName]) {
        [_rewardedVideoPlacementNameToSmashDelegate removeObjectForKey:placementName];
        [_rewardedVideoPlacementNameToTapjoyDelegate removeObjectForKey:placementName];
        [_rewardedVideoPlacementToIsReady removeObjectForKey:placementName];
        [_rewardedVideoPlacementNameToPlacement removeObjectForKey:placementName];
        [_rewardedVideoPlacementNamesForInitCallbacks removeObject:placementName];
        
    } else if ([_interstitialPlacementNameToPlacement objectForKey:placementName]) {
        [_interstitialPlacementNameToSmashDelegate removeObjectForKey:placementName];
        [_interstitialPlacementNameToTapjoyDelegate removeObjectForKey:placementName];
        [_interstitialPlacementToIsReady removeObjectForKey:placementName];
        [_interstitialPlacementNameToPlacement removeObjectForKey:placementName];
    }
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    NSString *consentValue = consent ? @"1" : @"0";
    LogAdapterApi_Internal(@"consent = %@", consentValue);
    [_privacyPolicy setUserConsent:consentValue];
    [_privacyPolicy setSubjectToGDPR:YES];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *) values {
    
    if (values.count == 0) {
        return;
    }
    
    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                           forType:(META_DATA_VALUE_BOOL)];
        if ([self isValidCOPPAMetaDataWithKey:key andValue:formattedValue]) {
            [self setCOPPAValue:[ISMetaDataUtils getCCPABooleanValue:formattedValue]];
        }
    }
}

- (void) setCCPAValue:(BOOL)value {
    NSString *ccpaValue = value ? @"1YY-" : @"1YN-";
    LogAdapterApi_Internal(@"value = %@", ccpaValue);
    [_privacyPolicy setUSPrivacy:ccpaValue];
}

- (void) setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value? @"YES" : @"NO");
    [_privacyPolicy setBelowConsentAge:value];
}

- (BOOL) isValidCOPPAMetaDataWithKey:(NSString*)key andValue:(NSString*)value {
    return (([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame) && (value.length > 0));
}

#pragma mark - Helper Methods

- (void)setTapjoyInitobserves {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tjcConnectSuccess:)
                                                 name:TJC_CONNECT_SUCCESS
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tjcConnectFail:)
                                                 name:TJC_CONNECT_FAILED
                                               object:nil];
}

- (void)setUserId {
    if (userId.length) {
        LogAdapterApi_Internal(@"set userID to %@", userId);
        [Tapjoy setUserIDWithCompletion:userId completion:^(BOOL success, NSError * _Nullable error) {
            if(success) {
                LogAdapterDelegate_Internal(@"setUserIdSuccess");
            } else {
                LogAdapterDelegate_Internal(@"setUserIdFailed - %@", error);
            }
        }];
    }
}

- (NSDictionary *)getBiddingData {
    if (_initState == INIT_STATE_FAILED) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        return nil;
    }
    
    NSString *bidderToken = [Tapjoy getUserToken];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}


// [TJPlacement placementWithName:] must run on same thread as [placement requestContent].
// Make sure that all methods that call getTJPlacement:tapjoyDelegate: are running on the same thread as [placement requestContent].
- (TJPlacement *)getTJPlacement:(NSString *)placementName
                 tapjoyDelegate:(id<TJPlacementDelegate>)tapjoyDelegate {
    
    TJPlacement *placement = [TJPlacement placementWithName:placementName
                                             mediationAgent:kMediationName
                                                mediationId:nil
                                                   delegate:tapjoyDelegate];
    
    if (placement != nil) {
        placement.adapterVersion = kAdapterVersion;
        return placement;
    } else {
        LogInternal_Error(@"error - TJPlacement is null");
        return nil;
    }
}

// [TJPlacement placementWithName:] must run on same thread as [placement requestContent].
// Make sure that all methods that call getTJBiddingPlacement:serverData:tapjoyDelegate: are running on the same thread as [placement requestContent].
- (TJPlacement *)getTJBiddingPlacement:(NSString *)placementName
                            serverData:(NSString *)serverData
                        tapjoyDelegate:(id<TJPlacementDelegate>)tapjoyDelegate {
    @try {
        TJPlacement *placement = [self getTJPlacement:placementName
                                       tapjoyDelegate:tapjoyDelegate];
        
        NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* jsonDic = [NSJSONSerialization JSONObjectWithData:data
                                                                options:0
                                                                  error:nil];
        NSString* auctionId = [jsonDic objectForKey:TJ_AUCTION_ID];
        NSString* auctionData = [jsonDic objectForKey:TJ_AUCTION_DATA];
        
        placement.auctionData = @{TJ_AUCTION_ID : auctionId, TJ_AUCTION_DATA : auctionData};
        
        return placement;
    } @catch (NSException *exception) {
        LogInternal_Error(@"exception = %@", exception);
        return nil;
    }
}

@end
