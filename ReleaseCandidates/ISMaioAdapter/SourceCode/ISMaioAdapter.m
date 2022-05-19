//
//  ISMaioAdapter.m
//  ISMaioAdapter
//
//  Created by Dor Alon on 16/10/2017.
//  Copyright © 2017 IronSource. All rights reserved.
//

//
//  IMPORTANT!
// 1. Maio is an automatic network. They cache all ads after being initialized.
// 2. Maio may change their initiation state from "Failed" to "Success" and vice versa
// 3. Maio's "maioDidFail" callback can be invoked at any time and can mean practically anything. If it is invoked with an empty zone Id, it means that it failed in initing the SDK.
// 4. A success to load a zone is reported by "maioDidChangeCanShow (true)" callback. A failure is reported by either "maioDidFail" or "maioDidChangeCanShow (false)"
//
// Since we cannot predict at what stage (IronSrc's init / load) OnFailed callback would be invoked, and cannot fully handle a change in init status,
// we decided to implemend the adapter in the following way:
//
// 1. Always assume that Maio was initialized successfully. It doesn't matter if the SDK was initialized, because we anyway need to wait for caching to complete.
// 2. Interpret Maio's callbacks (Success / Failed that can mean anything) as callbacks for load action and report to the smashes accordingly
// 3. To prevent timeouts and support cases in which RV is loaded before IS or the opposite, we need to know its load action was finished (if it has received a "maioDidChangeCanShow" or "maioDidFail" callback).
//    To do so we save a set (_mISZoneReceivedFirstStatus) and insert objects on callbacks.
// 4. No states are saved, we let Maio manage itself.
//
// Written by Roni Schwartz 26/11/18
//

#import "ISMaioAdapter.h"
#import "ISMaioAdapterSingleton.h"
#import <Maio/Maio.h>

static NSString * const kAdapterVersion = MaioAdapterVersion;
static NSString * const kMediaId        = @"mediaId";
static NSString * const kZoneId         = @"zoneId";


typedef NS_ENUM(NSInteger, MaioInitSate) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};

static MaioInitSate initState = INIT_STATE_NONE;

static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

static NSMutableSet* _mIsZoneReceivedFirstStatus = nil;

@interface ISMaioAdapter () <ISMaioDelegate, ISNetworkInitCallbackProtocol>
@end

@implementation ISMaioAdapter {
    // Rewarded video
    ConcurrentMutableDictionary* _zoneIdToRewardedVideoSmashDelegate;
    NSMutableSet*                _rewardedVideoPlacementsForInitCallbacks;
    
    // Interstitial
    ConcurrentMutableDictionary* _zoneIdToInterstitialSmashDelegate;
    
    // for auto init
}

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        
        if(initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        //auto init indicator
        if (_mIsZoneReceivedFirstStatus == nil) {
            _mIsZoneReceivedFirstStatus = [NSMutableSet set];

        }
        
        //rewarded video
        _zoneIdToRewardedVideoSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementsForInitCallbacks = [[NSMutableSet alloc] init];

        //interstitial
        _zoneIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [Maio sdkVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AVFoundation", @"CoreMedia", @"MobileCoreServices", @"StoreKit", @"SystemConfiguration", @"UIKit", @"WebKit"];;
}

- (NSString *)sdkName {
    return @"Maio";
}

#pragma mark - Rewarded Video

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");

    NSString *mediaId = adapterConfig.settings[kMediaId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
        
    if (![self isConfigValueValid:mediaId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kMediaId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
        
    LogAdapterApi_Internal(@"zoneId =  %@", zoneId);
    
    // register to singleton
    [[ISMaioAdapterSingleton sharedInstance] addRewardedVideoDelegate:self forZoneId:zoneId];
    
    // add listener to map
    [_zoneIdToRewardedVideoSmashDelegate setObject:delegate forKey:zoneId];
    
    // init sdk
    [self initWithMediaId:mediaId];
        
    if ([_mIsZoneReceivedFirstStatus containsObject:zoneId] || initState == INIT_STATE_FAILED) {
        if([Maio canShowAtZoneId:zoneId]){
            [delegate adapterRewardedVideoHasChangedAvailability:YES];
        }else{
            NSError *error = [ISError createError:ERROR_RV_LOAD_FAIL_UNEXPECTED withMessage:(initState == INIT_STATE_FAILED ? @"init failed" : @"no ad for zone id")];
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
            
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    } else {
        LogAdapterApi_Internal(@"waiting for instance init to complete");
    }
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");

    NSString *mediaId = adapterConfig.settings[kMediaId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
        
    if (![self isConfigValueValid:mediaId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kMediaId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
        
    LogAdapterApi_Internal(@"zoneId =  %@", zoneId);
    
    // register to singleton
    [[ISMaioAdapterSingleton sharedInstance] addRewardedVideoDelegate:self forZoneId:zoneId];
    
    // add listener to map
    [_zoneIdToRewardedVideoSmashDelegate setObject:delegate forKey:zoneId];
    [_rewardedVideoPlacementsForInitCallbacks addObject:zoneId];
    
    // init sdk
    [self initWithMediaId:mediaId];
    
    if (initState == INIT_STATE_SUCCESS) {
        [delegate adapterRewardedVideoInitSuccess];
    } else if (initState == INIT_STATE_FAILED) {
        NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"Maio SDK init failed"];
        [delegate adapterRewardedVideoInitFailed:error];
    } else {
        LogAdapterApi_Internal(@"waiting for instance init to complete");
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    if (![self isConfigValueValid:zoneId]) {
        NSError* error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId =  %@", zoneId);
    
    if ([Maio canShowAtZoneId:zoneId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            LogAdapterApi_Internal(@"call showAtZoneId");
            [Maio showAtZoneId:zoneId vc:viewController];
        });
    }
    else {
        LogAdapterApi_Internal(@"couldln't show ad");
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW];
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");

    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
        
    if (delegateRewardedVideo == nil) {
        LogAdapterApi_Internal(@"delegateRewardedVideo is nil");
        return;
    }
    
    if([Maio canShowAtZoneId:zoneId]){
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    } else {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    if (![self isConfigValueValid:zoneId]) {
        return NO;
    }
    
    return [Maio canShowAtZoneId:zoneId];
}
#pragma mark - Interstitial
-(void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate{
    LogAdapterApi_Internal(@"");
    
    NSString *mediaId = adapterConfig.settings[kMediaId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    if (![self isConfigValueValid:mediaId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kMediaId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"mediaId = %@, zoneId =  %@", mediaId, zoneId);
    
    // register to singleton
    [[ISMaioAdapterSingleton sharedInstance] addInterstitialDelegate:self forZoneId:zoneId];
    
    // add delegate to map
    [_zoneIdToInterstitialSmashDelegate setObject:delegate forKey:zoneId];
    
    // init SDK
    [self initWithMediaId:mediaId];
    
    // report on init success
    [delegate adapterInterstitialInitSuccess]; // TODO - is this correct? we do have a failed init handling in the adapter so why do we send init success without waiting for init response? this id not the same in Android
}

-(void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate{
    LogAdapterApi_Internal(@"");
    
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId =  %@", zoneId);
    
    if ([_mIsZoneReceivedFirstStatus containsObject:zoneId] || initState == INIT_STATE_FAILED) {
        if ([Maio canShowAtZoneId:zoneId]) {
            [delegate adapterInterstitialDidLoad];
        }
        else {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToLoadWithError:error];
        }
    }
    else {
        NSString *message = [NSString stringWithFormat:@"Maio loadInterstitialWithAdapterConfig <%@> waiting for instance init to complete", zoneId];
        LogAdapterApi_Internal(@"waiting for instance init to complete ");
        [self.logger log:message];
    }
    
}

-(void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate{
    LogAdapterApi_Internal(@"");
    
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    if (![self isConfigValueValid:zoneId]) {
        NSError* error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    if ([Maio canShowAtZoneId:zoneId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [Maio showAtZoneId:zoneId vc:viewController];
        });
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

-(BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig{
    LogAdapterApi_Internal(@"");
    
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    if (![self isConfigValueValid:zoneId]) {
        return NO;
    }
    
    return [Maio canShowAtZoneId:zoneId];
}

#pragma mark - Maio Delegate

- (void)maioDidInitialize {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_SUCCESS;
    
    // call init callback delegate success
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }

    // remove all init callback delegates
    [initCallbackDelegates removeAllObjects];
}

- (void)maioDidChangeCanShow:(NSString *)zoneId newValue:(BOOL)newValue {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    LogAdapterDelegate_Internal(@"newValue = %@", newValue ? @"YES" : @"NO");
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        return;
    }
    
    // add zoneid status to map
    [_mIsZoneReceivedFirstStatus addObject:zoneId];
    
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    id<ISInterstitialAdapterDelegate> delegateInterstitial = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    
    if (delegateRewardedVideo != nil) {
        if(newValue){
            [delegateRewardedVideo adapterRewardedVideoHasChangedAvailability:YES];
        }else{
            [delegateRewardedVideo adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    else if (delegateInterstitial != nil) {
        if (newValue){
            [delegateInterstitial adapterInterstitialDidLoad];
        } else {
            NSString *message = [NSString stringWithFormat:@"ISMaioAdapters: no ad available for zoneId %@", zoneId];
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:message];
            LogAdapterDelegate_Internal(@"error = %@", error);
            [delegateInterstitial adapterInterstitialDidFailToLoadWithError:error];
        }
    } else {
        LogAdapterDelegate_Internal(@"unknown zoneId");
    }
}

- (void)maioWillStartAd:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        return;
    }
    
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    id<ISInterstitialAdapterDelegate> delegateInterstitial = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    
    if (delegateRewardedVideo != nil) {
        [delegateRewardedVideo adapterRewardedVideoDidOpen];
        [delegateRewardedVideo adapterRewardedVideoDidStart];
        [delegateRewardedVideo adapterRewardedVideoHasChangedAvailability:NO];
    }
    else if (delegateInterstitial != nil) {
        [delegateInterstitial adapterInterstitialDidOpen];
        [delegateInterstitial adapterInterstitialDidShow];
    } else {
        LogAdapterDelegate_Internal(@"unknown zoneId");
    }
}

- (void)maioDidFinishAd:(NSString *)zoneId playtime:(NSInteger)playtime skipped:(BOOL)skipped rewardParam:(NSString *)rewardParam {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        return;
    }
    
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegateRewardedVideo != nil) {
        if (!skipped) {
            [delegateRewardedVideo adapterRewardedVideoDidEnd];
            [delegateRewardedVideo adapterRewardedVideoDidReceiveReward];
        }
    } else {
        LogAdapterDelegate_Internal(@"unknown zoneId");
    }
}

- (void)maioDidClickAd:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        return;
    }
    
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    id<ISInterstitialAdapterDelegate> delegateInterstitial = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    
    if (delegateRewardedVideo != nil) {
        [delegateRewardedVideo adapterRewardedVideoDidClick];
    } else if(delegateInterstitial != nil) {
        [delegateInterstitial adapterInterstitialDidClick];
    } else {
        LogAdapterDelegate_Internal(@"unknown zoneId");
    }
}

- (void)maioDidCloseAd:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        return;
    }
    
    id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    id<ISInterstitialAdapterDelegate> delegateInterstitial = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    
    if (delegateRewardedVideo != nil) {
        [delegateRewardedVideo adapterRewardedVideoDidClose];
    }
    else if (delegateInterstitial != nil) {
        [delegateInterstitial adapterInterstitialDidClose];
    } else {
        LogAdapterDelegate_Internal(@"unknown zoneId");
    }
}

- (void)logError:(NSString *)text zoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    LogAdapterDelegate_Internal(@"text = %@", text);
}

- (void)maioDidFail:(NSString *)zoneId reason:(MaioFailReason)reason {
        NSString *message = [NSString stringWithFormat:@"maioDidFail <%@> with reason: %@", zoneId, errorCodeToString(reason)];
        LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
        LogAdapterDelegate_Internal(@"reason = %@", errorCodeToString(reason));
        
        if ([zoneId length] == 0) {
            
            // set init state
            initState = INIT_STATE_FAILED;
            
            // call init callback delegate fail
            NSArray* initDelegatesList = initCallbackDelegates.allObjects;
            for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
                [initDelegate onNetworkInitCallbackFailed:@"Maio SDK init failed"];
            }
            
            // remove all init callback delegates
            [initCallbackDelegates removeAllObjects];
        }
        else {
            // add zoneid to status map
            [_mIsZoneReceivedFirstStatus addObject:zoneId];
            
            id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
            id<ISInterstitialAdapterDelegate> delegateInterstitial = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
            
            if (delegateRewardedVideo != nil) {
                if (![Maio canShowAtZoneId:zoneId]) {
                    [delegateRewardedVideo adapterRewardedVideoHasChangedAvailability:NO];
                    NSError *error = [ISError createError:ERROR_RV_LOAD_FAIL_UNEXPECTED withMessage:message];
                    [delegateRewardedVideo adapterRewardedVideoDidFailToLoadWithError:error];
                }
            }
            else if (delegateInterstitial != nil) {
                NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:message];
                [delegateInterstitial adapterInterstitialDidFailToLoadWithError:error];
            }
        }
    
}

static NSString* errorCodeToString(MaioFailReason reason) {
    NSString* reasonString = @"Unknown error";
    switch(reason) {
        // Unknown error
        case MaioFailReasonUnknown:
            reasonString = @"MaioFailReasonUnknown";
            break;
        // Out of stock
        case MaioFailReasonAdStockOut:
            reasonString = @"No ads to show";
            break;
        // Network connection error
        case MaioFailReasonNetworkConnection:
            reasonString = @"No internet connection";
            break;
        // HTTP status 4xx client error
        case MaioFailReasonNetworkClient:
            reasonString = @"MaioFailReasonNetworkClient";
            break;
        // HTTP status 5xx server error
        case MaioFailReasonNetworkServer:
            reasonString = @"MaioFailReasonNetworkServer";
            break;
        // SDK errors
        case MaioFailReasonSdk:
            reasonString = @"MaioFailReasonSdk";
            break;
        // Canceling a creative download
        case MaioFailReasonDownloadCancelled:
            reasonString = @"MaioFailReasonDownloadCancelled";
            break;
        // Video playback error
        case MaioFailReasonVideoPlayback:
            reasonString = @"MaioFailReasonVideoPlayback";
            break;
        // Media ID error
        case MaioFailReasonIncorrectMediaId:
            reasonString = @"MaioFailReasonIncorrectMediaId";
            break;
        // Zone ID error
        case MaioFailReasonIncorrectZoneId:
            reasonString = @"MaioFailReasonIncorrectZoneId";
            break;
        // Could not find an element to display
        case MaioFailReasonNotFoundViewContext:
            reasonString = @"MaioFailReasonNotFoundViewContext";
            break;
    }
    return reasonString;
}

#pragma mark - Init Maio

- (void)initWithMediaId:(NSString *)mediaId{
    
    // add self to init delegates only
    // when init not finished yet
    if(initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS){
        [initCallbackDelegates addObject:self];
    }
    
    // notice that dispatch_once is synchronous
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        if (initState == INIT_STATE_NONE) {
            
            // set init in progress
            initState = INIT_STATE_IN_PROGRESS;
            
            // init SDK
            dispatch_async(dispatch_get_main_queue(), ^{
                LogAdapterDelegate_Internal(@"mediaId = %@", mediaId);

                [[ISMaioAdapterSingleton sharedInstance] addFirstInitiatorDelegate:self];
                [Maio startWithMediaId:mediaId delegate:[ISMaioAdapterSingleton sharedInstance]];
            });
        }
    });
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterApi_Internal(@"");
    
    NSArray* interstitialPlacementIDs = _zoneIdToInterstitialSmashDelegate.allKeys;
    
    // interstitial
    for (NSString* placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegateInterstitial = [_zoneIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegateInterstitial adapterInterstitialInitSuccess];
    }
    
    NSArray* rewardedVideoPlacementIDs = _zoneIdToRewardedVideoSmashDelegate.allKeys;

    // rewarded
    for (NSString* placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:placementId];
        if ([_rewardedVideoPlacementsForInitCallbacks containsObject:placementId]) {
            [delegateRewardedVideo adapterRewardedVideoInitSuccess];
        } else {
            [delegateRewardedVideo adapterRewardedVideoHasChangedAvailability:YES];
        }
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    NSArray* interstitialPlacementIDs = _zoneIdToInterstitialSmashDelegate.allKeys;
    
    // interstitial
    for (NSString* placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegateInterstitial = [_zoneIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegateInterstitial adapterInterstitialInitFailedWithError:error];
    }
    
    NSArray* rewardedVideoPlacementIDs = _zoneIdToRewardedVideoSmashDelegate.allKeys;


    // rewarded
    for (NSString* placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegateRewardedVideo = [_zoneIdToRewardedVideoSmashDelegate objectForKey:placementId];
        if ([_rewardedVideoPlacementsForInitCallbacks containsObject:placementId]) {
            [delegateRewardedVideo adapterRewardedVideoInitFailed:error];
        } else {
            [delegateRewardedVideo adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
}

@end
