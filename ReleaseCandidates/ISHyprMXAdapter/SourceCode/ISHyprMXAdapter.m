//
//  Copyright (c) 2015 IronSource. All rights reserved.
//

#import "ISHyprMXRvListener.h"
#import "ISHyprMXIsListener.h"
#import "ISHyprMXAdapter.h"
#import <HyprMX/HyprMX.h>

static NSString * const kAdapterVersion         = HyprMXAdapterVersion;
static NSString * const kDistributorId          = @"distributorId";
static NSString * const kPropertyId             = @"propertyId";
static NSString * const kAdapterName            = @"HyprMX";
static NSString * const kHyprMarketplaceUserId  = @"HyprMX";
static NSString * const kMediationService       = @"ironsource";

static HyprConsentStatus _consent = CONSENT_STATUS_UNKNOWN;

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};

static InitState _initState = INIT_STATE_NONE;
static NSMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISHyprMXAdapter () <HyprMXInitializationDelegate,ISHyperMXRVDelegateWrapper, ISHyperMXISDelegateWrapper, ISNetworkInitCallbackProtocol>

@property (nonatomic, assign) BOOL lastReportedAvailability;

@end

@implementation ISHyprMXAdapter {
    ConcurrentMutableDictionary* _propertyIdToRvSmashDelegate;
    ConcurrentMutableDictionary* _propertyIdToRvHyprMxListener;
    ConcurrentMutableDictionary* _propertyIdToRvAd;
    ConcurrentMutableSet*        _rewardedVideoPropertiesForInitCallbacks;
    
    ConcurrentMutableDictionary* _propertyIdToIsSmashDelegate;
    ConcurrentMutableDictionary* _propertyIdToIsHyprMxListener;
    ConcurrentMutableDictionary* _propertyIdToIsAd;
    
    // availablity maps since hyprmx requires the main thread for checking availablity using their API
    ConcurrentMutableDictionary* _rvAdsAvailability;
    ConcurrentMutableDictionary* _isAdsAvailability;
}

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    if (self) {
        
        if(initCallbackDelegates == nil) {
            initCallbackDelegates = [NSMutableSet<ISNetworkInitCallbackProtocol> new];
        }
        
        _propertyIdToRvHyprMxListener = [ConcurrentMutableDictionary dictionary];
        _propertyIdToRvSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _propertyIdToRvAd = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPropertiesForInitCallbacks = [ConcurrentMutableSet set];
        
        _propertyIdToIsHyprMxListener = [ConcurrentMutableDictionary dictionary];
        _propertyIdToIsSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _propertyIdToIsAd = [ConcurrentMutableDictionary dictionary];
        
        _rvAdsAvailability = [ConcurrentMutableDictionary dictionary];
        _isAdsAvailability = [ConcurrentMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *) sdkVersion {
    return [HyprMX versionString];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport",
             @"AVFoundation",
             @"CoreGraphics",
             @"CoreMedia",
             @"CoreTelephony",
             @"EventKit",
             @"EventKitUI",
             @"Foundation",
             @"JavaScriptCore",
             @"MessageUI",
             @"MobileCoreServices",
             @"QuartzCore",
             @"SafariServices",
             @"StoreKit",
             @"SystemConfiguration",
             @"UIKit",
             @"WebKit"];
}
    
- (NSString *)sdkName {
    return @"HyprMX";
}

- (void)setConsent:(BOOL)consent {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock:^{
        
        _consent = consent ? CONSENT_GIVEN : CONSENT_DECLINED;
        if (_initState == INIT_STATE_SUCCESS) {
            LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
            [HyprMX setConsentStatus:_consent];
        }
    }];
}

#pragma mark - Rewarded Video

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userID
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock:^{
        
        NSString *userId = [self getUserId];
        NSString *distributorId = adapterConfig.settings[kDistributorId];
        NSString *propertyId = adapterConfig.settings[kPropertyId];
        
        if (![self isConfigValueValid:distributorId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kDistributorId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        if (![self isConfigValueValid:propertyId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kPropertyId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        if (![self isConfigValueValid:userId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:@"userId"];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        LogAdapterApi_Internal(@"distributorId = %@", distributorId);
        LogAdapterApi_Internal(@"userId = %@", userId);
        LogAdapterApi_Internal(@"propertyId = %@", propertyId);
           
        [_propertyIdToRvSmashDelegate setObject:delegate
                                         forKey:propertyId];
    
        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initSDK:distributorId
                       userId:userId];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                break;
            case INIT_STATE_SUCCESS: {
                HyprMXPlacement *rewardedPlacement = [self createRewardedVideoAd:propertyId];
                LogAdapterApi_Internal(@"propertyId = %@", propertyId);
                [rewardedPlacement loadAd];
                break;
            }
        }
    }];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userID
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock:^{
        
        NSString *userId = [self getUserId];
        NSString *distributorId = adapterConfig.settings[kDistributorId];
        NSString *propertyId = adapterConfig.settings[kPropertyId];
        
        if (![self isConfigValueValid:distributorId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kDistributorId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        if (![self isConfigValueValid:propertyId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kPropertyId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        if (![self isConfigValueValid:userId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:@"userId"];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        LogAdapterApi_Internal(@"distributorId = %@", distributorId);
        LogAdapterApi_Internal(@"userId = %@", userId);
        LogAdapterApi_Internal(@"propertyId = %@", propertyId);
           
        [_propertyIdToRvSmashDelegate setObject:delegate
                                         forKey:propertyId];
        [_rewardedVideoPropertiesForInitCallbacks addObject:propertyId];
        
        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initSDK:distributorId
                       userId:userId];
                break;
            case INIT_STATE_FAILED: {
                NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED
                                          withMessage:@"HyprMx SDK init failed"];
                LogAdapterApi_Internal(@"error = %@", error);
                [delegate adapterRewardedVideoInitFailed:error];
                break;
            }
            case INIT_STATE_SUCCESS:
                [self createRewardedVideoAd:propertyId];
                [delegate adapterRewardedVideoInitSuccess];
                break;
        }
    }];
}

- (HyprMXPlacement*)createRewardedVideoAd:(NSString*)propertyId {
    HyprMXPlacement *rewardedPlacement = [HyprMX getPlacement:propertyId];
    ISHyprMXRvListener *listener = [[ISHyprMXRvListener alloc] initWithPropertyId:propertyId
                                                                      andDelegate:self];
    rewardedPlacement.placementDelegate = listener; //using dedicated listener since the callbacks of RV and IS are the same
    [_propertyIdToRvHyprMxListener setObject:listener
                                      forKey:propertyId];
    [_propertyIdToRvAd setObject:rewardedPlacement
                          forKey:propertyId];
    return rewardedPlacement;
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock:^{
        NSString *propertyId = adapterConfig.settings[kPropertyId];
        LogAdapterApi_Internal(@"propertyId = %@", propertyId);
        HyprMXPlacement *rewardedPlacement = [_propertyIdToRvAd objectForKey:propertyId];
        if (rewardedPlacement != nil) {
                [rewardedPlacement loadAd];
        } else {
            id<ISRewardedVideoAdapterDelegate> delegate = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
            if (delegate != nil) {
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
            }
        }
    }];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                             delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        NSString *propertyId = adapterConfig.settings[kPropertyId];
        LogAdapterApi_Internal(@"propertyId = %@", propertyId);
        HyprMXPlacement *rewardedPlacement = [_propertyIdToRvAd objectForKey:propertyId];
        
        if (rewardedPlacement != nil && [rewardedPlacement isAdAvailable]) {
            [rewardedPlacement showAdFromViewController:viewController];
            LogAdapterApi_Internal(@"showAd");
        } else {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                      withMessage:@"ISHyprMXAdapter showRewardedVideoWithViewController"];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }

        [_rvAdsAvailability setObject:@NO
                               forKey:propertyId];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }];

}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *propertyId = adapterConfig.settings[kPropertyId];
    NSNumber *available = [_rvAdsAvailability objectForKey:propertyId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Interstitial

- (void)initInterstitialWithUserId:(NSString *)userID
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock:^{
        
        NSString *userId = [self getUserId];
        NSString *distributorId = adapterConfig.settings[kDistributorId];
        NSString *propertyId = adapterConfig.settings[kPropertyId];
        
        if (![self isConfigValueValid:distributorId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kDistributorId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        if (![self isConfigValueValid:propertyId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kPropertyId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        
        if (![self isConfigValueValid:userId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:@"userId"];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"distributorId = %@", distributorId);
        LogAdapterApi_Internal(@"userId = %@", userId);
        LogAdapterApi_Internal(@"propertyId = %@", propertyId);
        
        [_propertyIdToIsSmashDelegate setObject:delegate
                                         forKey:propertyId];
        
        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initSDK:distributorId
                       userId:userId];
                break;
            case INIT_STATE_FAILED: {
                NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED
                                          withMessage:@"HyprMx SDK init failed"];
                LogAdapterApi_Internal(@"error = %@", error);
                [delegate adapterInterstitialInitFailedWithError:error];
                break;
            }
            case INIT_STATE_SUCCESS: {
                HyprMXPlacement *isPlacement = [HyprMX getPlacement:propertyId];
                ISHyprMXIsListener *listener = [[ISHyprMXIsListener alloc] initWithPropertyId:propertyId
                                                                                  andDelegate:self];
                isPlacement.placementDelegate = listener; //using dedicated listener since the callbacks of RV and IS are the same
                [_propertyIdToIsHyprMxListener setObject:listener
                                                  forKey:propertyId];
                [_propertyIdToIsAd setObject:isPlacement
                                      forKey:propertyId];
                [delegate adapterInterstitialInitSuccess];
                break;
            }
        }
    }];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock:^{
        
        NSString *propertyId = adapterConfig.settings[kPropertyId];
        LogAdapterApi_Internal(@"propertyId = %@", propertyId);
        HyprMXPlacement *isPlacement = [_propertyIdToIsAd objectForKey:propertyId];
        if (isPlacement != nil) {
                LogAdapterApi_Internal(@"loadAd");
                [isPlacement loadAd];
        } else {
            id<ISInterstitialAdapterDelegate> adapterDelegate = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
            if (adapterDelegate != nil) {
                NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                          withMessage:@"loadInterstitialWithAdapterConfig"];
                LogAdapterApi_Internal(@"error = %@", error);
                [adapterDelegate adapterInterstitialDidFailToLoadWithError:error];
            }
        }
        
    }];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                            delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock: ^{
        
        NSString *propertyId = adapterConfig.settings[kPropertyId];
        LogAdapterApi_Internal(@"propertyId = %@", propertyId);
        HyprMXPlacement *isPlacement = [_propertyIdToIsAd objectForKey:propertyId];
        
        if (isPlacement != nil && [isPlacement isAdAvailable]) {
            [isPlacement showAdFromViewController:viewController];
            LogAdapterApi_Internal(@"showAd");
        } else {
            id<ISInterstitialAdapterDelegate> adapterDelegate = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
            if (adapterDelegate != nil) {
                NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                          withMessage:@"ISHyprMXAdapter showInterstitialWithViewController"];
                LogAdapterApi_Internal(@"error = %@", error);
                [adapterDelegate adapterInterstitialDidFailToShowWithError:error];
            }
        }
        
    }];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *propertyId = adapterConfig.settings[kPropertyId];
    NSNumber *available = [_isAdsAvailability objectForKey:propertyId];
    return (available != nil) && [available boolValue];
}

#pragma mark Helpers

- (void)initSDK:(NSString *)distributorId
         userId:(NSString *)userId {
    
    // add self to init delegates only
    // when init not finished yet
    if(_initState == INIT_STATE_NONE ||
       _initState == INIT_STATE_IN_PROGRESS){
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initOnceToken;
    dispatch_once(&initOnceToken, ^{
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                      withBlock:^{
            
            _initState = INIT_STATE_IN_PROGRESS;

            LogAdapterApi_Internal(@"distributorId = %@", distributorId);
            LogAdapterApi_Internal(@"userId = %@", userId);
            
            [HyprMX setMediationProvider:kMediationService
                      mediatorSDKVersion:MEDIATION_VERSION
                          adapterVersion:kAdapterVersion];
            [HyprMX initializeWithDistributorId:distributorId
                                         userId:userId
                                  consentStatus:_consent
                         initializationDelegate:self];
            
        }];
    });
}

- (NSString *) getUserId{
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:kHyprMarketplaceUserId];
    if (!userId) {
        userId = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:userId
                                                  forKey:kHyprMarketplaceUserId];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return userId;
}

#pragma mark HyprMx initialization delegate methods

- (void)initializationDidComplete {
    LogAdapterDelegate_Internal(@"");
    _initState = INIT_STATE_SUCCESS;

    if (_consent != CONSENT_STATUS_UNKNOWN) {
        [self setConsent:_consent == CONSENT_GIVEN ? YES : NO];
    }
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue()
                                  withBlock: ^{

        for (id<ISNetworkInitCallbackProtocol> initDelegate in initCallbackDelegates) {
            [initDelegate onNetworkInitCallbackSuccess];
        }
            
        // remove all init callback delegates
        [initCallbackDelegates removeAllObjects];
        
    }];
}

- (void)initializationFailed {
    LogAdapterDelegate_Internal(@"");
    _initState = INIT_STATE_FAILED;
        
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initCallbackDelegates) {
        [initDelegate onNetworkInitCallbackFailed:@"HyprMx failed to initialize"];
    }
        
    // remove all init callback delegates
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterApi_Internal(@"");
    
    NSArray *rewardedVideoPropertyIDs = _propertyIdToRvSmashDelegate.allKeys;

    // handle rewarded video
    for (NSString* propertyId in rewardedVideoPropertyIDs){
        HyprMXPlacement *rewardedPlacement = [HyprMX getPlacement:propertyId];
        ISHyprMXRvListener *listener = [[ISHyprMXRvListener alloc] initWithPropertyId:propertyId
                                                                          andDelegate:self];
        rewardedPlacement.placementDelegate = listener;
        [_propertyIdToRvHyprMxListener setObject:listener
                                          forKey:propertyId];
        [_propertyIdToRvAd setObject:rewardedPlacement
                              forKey:propertyId];
        
        if ([_rewardedVideoPropertiesForInitCallbacks hasObject:propertyId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            LogAdapterApi_Internal(@"load rewarded video");
            [rewardedPlacement loadAd];
        }
    }
    
    NSArray *interstitialPropertyIDs = _propertyIdToIsSmashDelegate.allKeys;

    for (NSString* propertyId in interstitialPropertyIDs){
        HyprMXPlacement *isPlacement = [HyprMX getPlacement:propertyId];
        ISHyprMXIsListener *listener = [[ISHyprMXIsListener alloc] initWithPropertyId:propertyId
                                                                          andDelegate:self];
        isPlacement.placementDelegate = listener;
        [_propertyIdToIsHyprMxListener setObject:listener
                                          forKey:propertyId];
        [_propertyIdToIsAd setObject:isPlacement
                              forKey:propertyId];
        id<ISInterstitialAdapterDelegate> islistener = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
        
        if (islistener != nil) {
            [islistener adapterInterstitialInitSuccess];
        }
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED
                              withMessage:errorMessage];
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    NSArray *rewardedVideoPropertyIDs = _propertyIdToRvSmashDelegate.allKeys;
    
    for (NSString* propertyId in rewardedVideoPropertyIDs){
         id<ISRewardedVideoAdapterDelegate> delegate = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
        if ([_rewardedVideoPropertiesForInitCallbacks hasObject:propertyId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    NSArray *interstitialPropertyIDs = _propertyIdToIsSmashDelegate.allKeys;

    for (NSString* propertyId in interstitialPropertyIDs){
        id<ISInterstitialAdapterDelegate> delegate = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video Delegate

- (void)adWillStartForRvProperty:(NSString *)propertyId {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISRewardedVideoAdapterDelegate> rvlistener = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
    
    if (rvlistener != nil) {
        [rvlistener adapterRewardedVideoDidOpen];
    }
}

- (void)adDidCloseForRvProperty:(NSString *)propertyId
                    didFinishAd:(BOOL)finished {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISRewardedVideoAdapterDelegate> rvlistener = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
    
    if (rvlistener != nil) {
        [rvlistener adapterRewardedVideoDidClose];
    }
}

- (void)adDisplayErrorForRvProperty:(NSString *)propertyId
                              error:(HyprMXError)hyprMXError {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISRewardedVideoAdapterDelegate> rvlistener = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
    if (rvlistener != nil) {
        [rvlistener adapterRewardedVideoHasChangedAvailability:NO];
        NSError *error = [NSError errorWithDomain:@"HyprMX"
                                             code:hyprMXError
                                         userInfo:@{NSLocalizedDescriptionKey : @"adDisplayErrorForRvProperty Failed"}];
        LogAdapterDelegate_Internal(@"error = %@", error);
        [rvlistener adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (void)adAvailableForRvProperty:(NSString *)propertyId {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    [_rvAdsAvailability setObject:@YES
                           forKey:propertyId];
    id<ISRewardedVideoAdapterDelegate> rvlistener = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
    if (rvlistener != nil) {
        [rvlistener adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)adNotAvailableForRvProperty:(NSString *)propertyId {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    [_rvAdsAvailability setObject:@NO
                           forKey:propertyId];
    id<ISRewardedVideoAdapterDelegate> rvlistener = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
    if (rvlistener != nil) {
        [rvlistener adapterRewardedVideoHasChangedAvailability:NO];
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:@"adNotAvailableForRvProperty"];
        LogAdapterDelegate_Internal(@"error = %@", error);
        [rvlistener adapterRewardedVideoDidFailToLoadWithError:error];
    }
}

- (void)adDidRewardForRvProperty:(NSString *)propertyId
                      rewardName:(NSString *)rewardName
                     rewardValue:(NSInteger)rewardValue {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISRewardedVideoAdapterDelegate> listener = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
    if (listener != nil) {
        [listener adapterRewardedVideoDidReceiveReward];
    }
}

- (void)adExpiredForRvProperty:(NSString *)propertyId {
    // update avaialbilty map in order for adapter to answer availability API correctly, no need to update smash here on availablility
    [_rvAdsAvailability setObject:@NO
                           forKey:propertyId];
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISRewardedVideoAdapterDelegate> listener = [_propertyIdToRvSmashDelegate objectForKey:propertyId];
    if (listener != nil) {
        NSError *error = [ISError createError:ERROR_RV_EXPIRED_ADS
                                  withMessage:@"ads are expired"];
        [listener adapterRewardedVideoDidFailToLoadWithError:error];
    }

}

#pragma mark - Interstitial Delegate

- (void)adWillStartForIsProperty:(NSString *)propertyId {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISInterstitialAdapterDelegate> islistener = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
    if (islistener != nil) {
        [islistener adapterInterstitialDidOpen];
        [islistener adapterInterstitialDidShow];
    }
}

- (void)adDidCloseForIsProperty:(NSString *)propertyId
                    didFinishAd:(BOOL)finished {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISInterstitialAdapterDelegate> islistener = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
    if (islistener != nil) {
        [islistener adapterInterstitialDidClose];
    }
}

- (void)adDisplayErrorForIsProperty:(NSString *)propertyId
                              error:(HyprMXError)hyprMXError {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    id<ISInterstitialAdapterDelegate> islistener = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
    if (islistener != nil) {
        NSError *error = [NSError errorWithDomain:@"HyprMX"
                                             code:hyprMXError
                                         userInfo:@{NSLocalizedDescriptionKey : @"is adDisplayErrorForIsProperty Failed"}];
        LogAdapterDelegate_Internal(@"error = %@", error);
        [islistener adapterInterstitialDidFailToShowWithError:error];
    }
}

- (void)adAvailableForIsProperty:(NSString *)propertyId {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    [_isAdsAvailability setObject:@YES
                           forKey:propertyId];
    id<ISInterstitialAdapterDelegate> islistener = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
    if (islistener != nil) {
        [islistener adapterInterstitialDidLoad];
    }
}

- (void)adNotAvailableForIsProperty:(NSString *)propertyId {
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
    [_isAdsAvailability setObject:@NO
                           forKey:propertyId];
    id<ISInterstitialAdapterDelegate> islistener = [_propertyIdToIsSmashDelegate objectForKey:propertyId];
    if (islistener != nil) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:@"adNotAvailableForIsProperty"];
        LogAdapterDelegate_Internal(@"error = %@", error);
        [islistener adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (void)adExpiredForIsProperty:(NSString *)propertyId {
    // update avaialbilty map in order for adapter to answer availability API correctly, no need to update smash here on availablility
    [_isAdsAvailability setObject:@NO
                           forKey:propertyId];
    LogAdapterDelegate_Internal(@"propertyId = %@", propertyId);
}

@end
