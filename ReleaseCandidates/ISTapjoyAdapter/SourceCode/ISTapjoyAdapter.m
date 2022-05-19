//
//  ISTapjoyAdapter.m
//  ISTapjoyAdapter
//
//  Created by Daniil Bystrov on 4/13/16.
//  Copyright © 2016 IronSource. All rights reserved.
//

// Melinda Tang from Tapjoy
// Update: 9/1/19
//
// Some methods should be be called from the main thread:
// - placement.isContentAvailable
// placement.isContentReady
// - [placement showContentWithViewController:]
//
// Don’t necessarily need to be called from main thread, but at least should be called on the same thread as each other:
// - [TJPlacement placementWithName:]
// - [placement requestContent];


#import "ISTapjoyAdapter.h"
#import <Tapjoy/TJPlacement.h>
#import <Tapjoy/Tapjoy.h>

static NSString * const kAdapterVersion     = TapjoyAdapterVersion;
static NSString * const kAppId              = @"sdkKey";
static NSString * const kPlacement          = @"placementName";
static NSString * const kMetaDataCOPPAKey   = @"Tapjoy_COPPA";

static NSInteger const PROG_LOAD_ERROR_GET_PLACEMENT = 5000;
static NSInteger const LOAD_ERROR_NOT_AVAILABLE = 5001;

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_ERROR,
    INIT_STATE_SUCCESS
};
#define ISAdapterStateString(enum) [@[@"INIT_STATE_NONE",@"INIT_STATE_IN_PROGRESS",@"INIT_STATE_ERROR",@"INIT_STATE_SUCCESS"] objectAtIndex:enum]

static InitState _initState = INIT_STATE_NONE;
static TJPrivacyPolicy * _privacyPolicy;
static NSString *userId = @"";

static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISTapjoyAdapter () <TJPlacementDelegate, TJPlacementVideoDelegate, ISNetworkInitCallbackProtocol>
{
    // Rewarded video
    ConcurrentMutableDictionary* _rvPlacementNameToDelegate;
    NSMutableDictionary* _rvPlacementNameToPlacement;
    ConcurrentMutableDictionary* _rvPlacementToIsReady;

    // Interstitial
    ConcurrentMutableDictionary* _isPlacementNameToDelegate;
    NSMutableDictionary* _isPlacementNameToPlacement;
    ConcurrentMutableDictionary* _isPlacementToIsReady;
    
    NSMutableSet*        _programmaticPlacementNames;
}

@end

@implementation ISTapjoyAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    if (self) {
        
        if(initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tjcConnectSuccess:)
                                                     name:TJC_CONNECT_SUCCESS
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tjcConnectFail:)
                                                     name:TJC_CONNECT_FAILED
                                                   object:nil];
        
        _rvPlacementNameToDelegate = [ConcurrentMutableDictionary dictionary];
        _rvPlacementNameToPlacement = [NSMutableDictionary dictionary];
        _rvPlacementToIsReady = [ConcurrentMutableDictionary dictionary];
        
        _isPlacementNameToDelegate = [ConcurrentMutableDictionary dictionary];
        _isPlacementNameToPlacement = [NSMutableDictionary dictionary];
        _isPlacementToIsReady = [ConcurrentMutableDictionary dictionary];
        
        _programmaticPlacementNames = [NSMutableSet new];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
        
        _privacyPolicy = [Tapjoy getPrivacyPolicy];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [Tapjoy getVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"CFNetwork", @"CoreData", @"CoreTelephony", @"SystemConfiguration", @"StoreKit", @"UIKit", @"WebKit"];
}

- (NSString *)sdkName {
    return @"Tapjoy";
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [_privacyPolicy setUserConsent:consent ? @"1" : @"0"];
    [_privacyPolicy setSubjectToGDPR:YES];
}

- (void)setMetaDataWithKey:(NSString *)key andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
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
    LogAdapterApi_Internal(@"value = %@", value? @"YES" : @"NO");
    [_privacyPolicy setUSPrivacy:value ? @"1YY-" : @"1YN-"];
}

- (void) setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value? @"YES" : @"NO");
    [_privacyPolicy setBelowConsentAge:value];
}

- (BOOL) isValidCOPPAMetaDataWithKey:(NSString*)key andValue:(NSString*)value {
    return (([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame) && (value.length > 0));
}


#pragma mark - Rewarded Video

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString* appId = adapterConfig.settings[kAppId];
    NSString* placementName = adapterConfig.settings[kPlacement];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:placementName]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacement];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementName = %@", placementName);
    
    [_rvPlacementToIsReady setObject:@NO forKey:placementName];
    [_programmaticPlacementNames addObject:placementName];
    [_rvPlacementNameToDelegate setObject:delegate forKey:placementName];
    [self initWithUserId:userId appId:appId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        [delegate adapterRewardedVideoInitSuccess];
    }
    else if (_initState == INIT_STATE_ERROR) {
        NSError *error = [NSError errorWithDomain:@"Tapjoy" code:506 userInfo:@{NSLocalizedDescriptionKey : @"init error"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
    }
}


// [TJPlacement placementWithName:] must run on same thread as [placement requestContent].
// Make sure that all methods that are using them are running on the main thread
- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData
                           delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* placementName = adapterConfig.settings[kPlacement];
        LogAdapterApi_Internal(@"placementName = %@", placementName);
        TJPlacement* placement = [self getPlacementForBidding:placementName serverData:serverData];
        
        if (placement == nil) {
            NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:PROG_LOAD_ERROR_GET_PLACEMENT userInfo:@{NSLocalizedDescriptionKey : @"Load error"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
            return;
        }
        
        placement.videoDelegate = self;
        [_rvPlacementNameToPlacement setObject:placement forKey:placementName];
        [placement requestContent];
    });
}


- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString* appId = adapterConfig.settings[kAppId];
    NSString* placementName = adapterConfig.settings[kPlacement];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:placementName]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacement];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementName = %@", placementName);
    
    [_rvPlacementToIsReady setObject:@NO forKey:placementName];
    [_rvPlacementNameToDelegate setObject:delegate forKey:placementName];
    [self initWithUserId:userId appId:appId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"load video");
        [self loadVideoInternal:placementName];
    }
    else if (_initState == INIT_STATE_ERROR) {
        LogAdapterApi_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig
                             delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* placementName = adapterConfig.settings[kPlacement];
        TJPlacement* placement = [_rvPlacementNameToPlacement objectForKey:placementName];
        [_rvPlacementToIsReady setObject:@NO forKey:placementName];
        LogAdapterApi_Internal(@"placementName = %@", placementName);
        if (placement != nil && placement.isContentReady) {
            LogAdapterApi_Internal(@"showContentWithViewController");
            [placement showContentWithViewController:viewController];
        }
        else {
            NSString *desc = [NSString stringWithFormat:@"showRewardedVideo: unknown placement %@", placement];
            NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : desc}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    });
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString* placementName = adapterConfig.settings[kPlacement];
    [_rvPlacementToIsReady setObject:@NO forKey:placementName];

    LogAdapterApi_Internal(@"placementName = %@", placementName);
    if ([_rvPlacementNameToPlacement objectForKey:placementName]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[_rvPlacementNameToPlacement objectForKey:placementName] requestContent];
        });
    }
    else {
        if (delegate != nil) {
            LogAdapterApi_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
            NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:LOAD_ERROR_NOT_AVAILABLE userInfo:@{NSLocalizedDescriptionKey : @"unknown placement"}];
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        }
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    if ([_rvPlacementToIsReady objectForKey:adapterConfig.settings[kPlacement]]) {
        return [[_rvPlacementToIsReady objectForKey:adapterConfig.settings[kPlacement]] boolValue];
    }
    else {
        return NO;
    }
}

#pragma mark - Interstitial

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementName = adapterConfig.settings[kPlacement];
        LogAdapterApi_Internal(@"placementName = %@", placementName);
        TJPlacement* placement = [self getPlacementForBidding:placementName serverData:serverData];
        if (placement == nil) {
            NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:PROG_LOAD_ERROR_GET_PLACEMENT userInfo:@{NSLocalizedDescriptionKey : @"Load error"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToLoadWithError:error];
            return;
        }
        
        [_isPlacementToIsReady setObject:@NO forKey:placementName];
        placement.videoDelegate = self;
        [_isPlacementNameToPlacement setObject:placement forKey:placementName];
        [placement requestContent];
    });
}

- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString* appId = adapterConfig.settings[kAppId];
    NSString* placementName = adapterConfig.settings[kPlacement];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementName]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacement];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    LogAdapterApi_Internal(@"placementName = %@", placementName);
    
    [_isPlacementNameToDelegate setObject:delegate forKey:placementName];
    [self initWithUserId:userId appId:appId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        [delegate adapterInterstitialInitSuccess];
    }
    else if (_initState == INIT_STATE_ERROR) {
        NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey : @"init failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementName = adapterConfig.settings[kPlacement];
        TJPlacement* placement = [self getPlacement:placementName];
        [_isPlacementToIsReady setObject:@NO forKey:placementName];
        placement.videoDelegate = self;
        [_isPlacementNameToPlacement setObject:placement forKey:placementName];
        LogAdapterApi_Internal(@"placementName = %@", placementName);
        [placement requestContent];
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* placementName = adapterConfig.settings[kPlacement];
        TJPlacement* placement = [_isPlacementNameToPlacement objectForKey:placementName];
        [_isPlacementToIsReady setObject:@NO forKey:placementName];
        LogAdapterApi_Internal(@"placementName = %@", placementName);
        if (placement != nil && placement.isContentReady) {
            LogAdapterApi_Internal(@"showContentWithViewController - placementName = %@", placementName);
            [placement showContentWithViewController:viewController];
        }
        else {
            NSString *desc = [NSString stringWithFormat:@"Show interstitial failed - no ads to show"];
            NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey : desc}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    });
}


- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    if ([_isPlacementToIsReady objectForKey:adapterConfig.settings[kPlacement]]) {
        return [[_isPlacementToIsReady objectForKey:adapterConfig.settings[kPlacement]] boolValue];
    }
    else {
        return NO;
    }
}

- (void)loadVideoInternal:(NSString *)placementName {
    dispatch_async(dispatch_get_main_queue(), ^{
        TJPlacement* placement = [self getPlacement:placementName];
        placement.videoDelegate = self;
        [_rvPlacementNameToPlacement setObject:placement forKey:placementName];
        LogAdapterApi_Internal(@"placementName = %@", placementName);
        [placement requestContent];
    });
}


// [TJPlacement placementWithName:] must run on same thread as [placement requestContent].
// Make sure that all methods that call getPlacement are running on the main thread
- (TJPlacement *)getPlacement:(NSString *)placementName {
    TJPlacement *placement = [TJPlacement placementWithName:placementName mediationAgent:@"ironsource" mediationId:nil delegate:self];
    placement.adapterVersion = kAdapterVersion;
    return placement;
}

// [TJPlacement placementWithName:] must run on same thread as [placement requestContent].
// Make sure that all methods that call getPlacementForBidding are running on the main thread
- (TJPlacement *)getPlacementForBidding:(NSString *)placementName serverData:(NSString *)serverData {
    @try {
        TJPlacement *placement = [self getPlacement:placementName];
        NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* jsonDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString* auctionId = [jsonDic objectForKey:TJ_AUCTION_ID];
        NSString* auctionData = [jsonDic objectForKey:TJ_AUCTION_DATA];
        
        placement.auctionData = @{TJ_AUCTION_ID : auctionId, TJ_AUCTION_DATA : auctionData};
        return placement;
    }
    @catch (NSException *exception) {
        LogAdapterApi_Internal(@"exception = %@", exception);
        return nil;
    }
}

#pragma mark - Tapjoy Delegate

- (void)requestDidSucceed:(TJPlacement *)placement {
    dispatch_async(dispatch_get_main_queue(), ^{
        LogAdapterDelegate_Internal(@"");
        LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
        if (placement.isContentAvailable) {
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:LOAD_ERROR_NOT_AVAILABLE userInfo:@{NSLocalizedDescriptionKey : @"No content available"}];
            if ([_rvPlacementNameToDelegate objectForKey:placement.placementName]) {
                LogAdapterDelegate_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
                [[_rvPlacementNameToDelegate objectForKey:placement.placementName] adapterRewardedVideoHasChangedAvailability:NO];
                [[_rvPlacementNameToDelegate objectForKey:placement.placementName] adapterRewardedVideoDidFailToLoadWithError:error];
            }
            else if ([_isPlacementNameToDelegate objectForKey:placement.placementName]) {
                LogAdapterDelegate_Internal(@"error = %@", error);
                [[_isPlacementNameToDelegate objectForKey:placement.placementName] adapterInterstitialDidFailToLoadWithError:error];
            }
            else {
                LogAdapterDelegate_Internal(@"unknown placement");
            }
        });
    });
}

// Called when there was a problem during connecting Tapjoy servers.
- (void)requestDidFail:(TJPlacement *)placement error:(NSError *)error {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    if ([_rvPlacementNameToDelegate objectForKey:placement.placementName]) {
        [[_rvPlacementNameToDelegate objectForKey:placement.placementName] adapterRewardedVideoHasChangedAvailability:NO];
        [[_rvPlacementNameToDelegate objectForKey:placement.placementName] adapterRewardedVideoDidFailToLoadWithError:error];
    }
    else if ([_isPlacementNameToDelegate objectForKey:placement.placementName]) {
        [[_isPlacementNameToDelegate objectForKey:placement.placementName] adapterInterstitialDidFailToLoadWithError:error];
    }
    else {
        LogAdapterDelegate_Internal(@"unknown placement");
    }
}

// Called when the content is actually available to display.
- (void)contentIsReady:(TJPlacement *)placement {
    NSString* placementName = placement.placementName;
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    
    if ([_rvPlacementNameToDelegate objectForKey:placementName]) {
        [[_rvPlacementNameToDelegate objectForKey:placementName] adapterRewardedVideoHasChangedAvailability:YES];
        [_rvPlacementToIsReady setObject:@YES forKey:placementName];
    }
    else if ([_isPlacementNameToDelegate objectForKey:placementName]) {
        [[_isPlacementNameToDelegate objectForKey:placementName] adapterInterstitialDidLoad];
        [_isPlacementToIsReady setObject:@YES forKey:placementName];
    }
    else {
        LogAdapterDelegate_Internal(@"unknown placement");
    }
}

// Called when the content is shown.
- (void)contentDidAppear:(TJPlacement *)placement {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
}

// Called when the content is dismissed.
- (void)contentDidDisappear:(TJPlacement *)placement {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    
    if (placement.placementName.length == 0) {
        return;
    }
    
    /* Get delegate for placement */
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_rvPlacementNameToDelegate objectForKey:placement.placementName];
    id<ISInterstitialAdapterDelegate> delegateInterstitial = [_isPlacementNameToDelegate objectForKey:placement.placementName];
    
    if (delegateRewardedVideo) {        
        [delegateRewardedVideo adapterRewardedVideoDidClose];
    }
    else if (delegateInterstitial) {
        [delegateInterstitial adapterInterstitialDidClose];
    }
    else {
        LogAdapterDelegate_Internal(@"unknown placement");
    }
}

// Called when a click event has occurred
- (void)didClick:(TJPlacement*)placement {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    
    if (placement.placementName.length == 0) {
        return;
    }
    
    /* Get delegate for placement */
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_rvPlacementNameToDelegate objectForKey:placement.placementName];
    id<ISInterstitialAdapterDelegate> delegateInterstitial = [_isPlacementNameToDelegate objectForKey:placement.placementName];
    
    if (delegateRewardedVideo) {
        [delegateRewardedVideo adapterRewardedVideoDidClick];
    }
    else if (delegateInterstitial) {
        [delegateInterstitial adapterInterstitialDidClick];
    }
    else {
        LogAdapterDelegate_Internal(@"unknown placement");
    }
}

// Callback issued by TJ to publisher when the user has successfully completed a purchase request
- (void)placement:(TJPlacement *)placement didRequestPurchase:(TJActionRequest *)request productId:(NSString *)productId {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    LogAdapterDelegate_Internal(@"request = %@", request);
    LogAdapterDelegate_Internal(@"productId = %@", productId);
}

// Callback issued by TJ to publisher when the user has successfully requests a reward
- (void)placement:(TJPlacement *)placement didRequestReward:(TJActionRequest *)request itemId:(NSString *)itemId quantity:(int)quantity {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    LogAdapterDelegate_Internal(@"request = %@", request);
    LogAdapterDelegate_Internal(@"itemId = %@", itemId);
}

- (void)videoDidStart:(TJPlacement *)placement{
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    
    /* Get delegate for placement */
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_rvPlacementNameToDelegate objectForKey:placement.placementName];
    id<ISInterstitialAdapterDelegate> delegateInterstitial = [_isPlacementNameToDelegate objectForKey:placement.placementName];
    
    /* RewardedVideo */
    if (delegateRewardedVideo) {
        [delegateRewardedVideo adapterRewardedVideoDidOpen];
        [delegateRewardedVideo adapterRewardedVideoDidStart];
    }
    /* Interstitial */
    else if (delegateInterstitial) {
        [delegateInterstitial adapterInterstitialDidOpen];
        [delegateInterstitial adapterInterstitialDidShow];
    }
    else {
        LogAdapterDelegate_Internal(@"unknown placement");
    }
}

- (void)videoDidComplete:(TJPlacement *)placement {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_rvPlacementNameToDelegate objectForKey:placement.placementName];
    if (delegateRewardedVideo) {
        [delegateRewardedVideo adapterRewardedVideoDidReceiveReward];
        [delegateRewardedVideo adapterRewardedVideoDidEnd];
    }
}

- (void)videoDidFail:(TJPlacement *)placement error:(NSString *)errorMsg {
    LogAdapterDelegate_Internal(@"placement.placementName = %@", placement.placementName);
    LogAdapterDelegate_Internal(@"errorMsg = %@", errorMsg);
    
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_rvPlacementNameToDelegate objectForKey:placement.placementName];
    if (delegateRewardedVideo) {
        NSString *desc = [NSString stringWithFormat:@"videoDidFail for placement: %@ with reason - %@", placement, errorMsg];
        NSError *error = [NSError errorWithDomain:@"ISTapjoyAdapter" code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : desc}];
        [delegateRewardedVideo adapterRewardedVideoDidFailToShowWithError:error];
    }
}


#pragma mark - Private Methods

- (void)initWithUserId:(NSString *)userId appId:(NSString *)appId {
    LogAdapterApi_Internal(@"_initState = %@", ISAdapterStateString(_initState));
    
    // add self to init delegates only
    // when init not finished yet
    if(_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS){
        LogAdapterApi_Internal(@"adding to init callbacks - %ld", [self hash]);
        [initCallbackDelegates addObject:self];
    }
    
    if (_initState == INIT_STATE_NONE) {
        _initState = INIT_STATE_IN_PROGRESS;
        LogAdapterApi_Internal(@"appId = %@", appId);
        LogAdapterApi_Internal(@"userId = %@", userId);
        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [Tapjoy enableLogging:[ISConfigurations getConfigurations].adaptersDebug];
            [Tapjoy setDebugEnabled:[ISConfigurations getConfigurations].adaptersDebug];
            LogAdapterApi_Internal(@"enableLogging=%d", [ISConfigurations getConfigurations].adaptersDebug);

        }
        self.userId = userId;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                LogAdapterApi_Internal(@"Tapjoy connect");
                [Tapjoy connect:appId];
            });
        });
    }
}

- (NSDictionary *)getBiddingData {
    if (_initState == INIT_STATE_ERROR) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        return nil;
    }
    
    NSString *bidderToken = [Tapjoy getUserToken];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

#pragma mark - Notification Methods

- (void)tjcConnectSuccess:(NSNotification *)notifyObj {
    LogAdapterApi_Internal(@"");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_SUCCESS object:nil];

    _initState = INIT_STATE_SUCCESS;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate success
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    [initCallbackDelegates removeAllObjects];

    
}

- (void)tjcConnectFail:(NSNotification *)notifyObj {
    LogAdapterApi_Internal(@"");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_CONNECT_FAILED object:nil];

    _initState = INIT_STATE_ERROR;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate fail
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackFailed:@"TapJoy SDK init failed"];
    }
    [initCallbackDelegates removeAllObjects];

}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterApi_Internal(@"");
    
    // set user id
    [self setUserId];
    
    // interstitial
    NSArray *interstitialPlacementIDs = _isPlacementNameToDelegate.allKeys;
    
    for (NSString *placementName in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_isPlacementNameToDelegate objectForKey:placementName];
        LogAdapterApi_Internal(@"adapterInterstitialInitSuccess");
        [delegate adapterInterstitialInitSuccess];
    }
        
    // rewarded
    NSArray *rewardedVideoPlacementIDs = _rvPlacementNameToDelegate.allKeys;
    
    for (NSString* placementName in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rvPlacementNameToDelegate objectForKey:placementName];
        if ([_programmaticPlacementNames containsObject:placementName]) {
            LogAdapterApi_Internal(@"adapterRewardedVideoInitSuccess - placementName = %@", placementName);
            [delegate adapterRewardedVideoInitSuccess];
        }
        else {
            LogAdapterApi_Internal(@"loadVideoInternal - placementName = %@", placementName);
            [self loadVideoInternal:placementName];
        }
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    // interstitial
    NSArray *interstitialPlacementIDs = _isPlacementNameToDelegate.allKeys;
    
    for (NSString *placementName in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_isPlacementNameToDelegate objectForKey:placementName];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // rewarded
    NSArray *rewardedVideoPlacementIDs = _rvPlacementNameToDelegate.allKeys;
    
    for (NSString* placementName in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rvPlacementNameToDelegate objectForKey:placementName];
        if ([_programmaticPlacementNames containsObject:placementName]) {
            [delegate adapterRewardedVideoInitFailed:error];
        }
        else {
            LogAdapterApi_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
}

- (void)setUserId {
    if (userId.length) {
        LogAdapterApi_Internal(@"set userID to %@", userId);
        dispatch_async(dispatch_get_main_queue(), ^{
            [Tapjoy setUserIDWithCompletion:userId completion:^(BOOL success, NSError * _Nullable error) {
                if(success) {
                    LogAdapterApi_Internal(@"setUserIdSuccess");
                } else {
                    LogAdapterApi_Internal(@"setUserIdFailed - %@", error);
                }
            }];
        });

    }
}

@end
