//
//  ISFacebookAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <FBAudienceNetwork/FBAudienceNetwork.h>

#import "ISFacebookAdapter.h"
#import "ISFacebookRewardedVideoAdapter.h"
#import "ISFacebookInterstitialAdapter.h"
#import "ISFacebookBannerAdapter.h"
#import <ISFacebookNativeAdAdapter.h>

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState initState = INIT_STATE_NONE;

static NSString* _mediationService = nil;

@interface ISFacebookAdapter () <ISNetworkInitCallbackProtocol>

@end

@implementation ISFacebookAdapter

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return FacebookAdapterVersion;
}

- (NSString *)sdkVersion {
    return FB_AD_SDK_VERSION;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISFacebookRewardedVideoAdapter *rewardedVideoAdapter = [[ISFacebookRewardedVideoAdapter alloc] initWithFacebookAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISFacebookInterstitialAdapter *interstitialAdapter = [[ISFacebookInterstitialAdapter alloc] initWithFacebookAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        // Banner
        ISFacebookBannerAdapter *bannerAdapter = [[ISFacebookBannerAdapter alloc] initWithFacebookAdapter:self];
        [self setBannerAdapter:bannerAdapter];

        // NativeAd
        ISFacebookNativeAdAdapter *netiveAdAdapter = [[ISFacebookNativeAdAdapter alloc] initWithFacebookAdapter:self];
        [self setNativeAdAdapter:netiveAdAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithPlacementIds:(NSString *)allPlacementIds {
        
    // add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        initState = INIT_STATE_IN_PROGRESS;
        
        NSArray* placementIdsArray = [allPlacementIds componentsSeparatedByString:@","];

        FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:placementIdsArray
                                                                       mediationService:[self getMediationService]];
                
        // check if debug mode needed
        FBAdLogLevel logLevel =[ISConfigurations getConfigurations].adaptersDebug ? FBAdLogLevelVerbose : FBAdLogLevelNone;
        [FBAdSettings setLogLevel:logLevel];
        
        LogAdapterApi_Internal(@"Initialize Meta with placementIds = %@", placementIdsArray);
        
        ISFacebookAdapter * __weak weakSelf = self;
        [FBAudienceNetworkAds initializeWithSettings:initSettings
                                   completionHandler:^(FBAdInitResults *results) {
                                
            if (results.success) {
                // call init callback delegate success
                [weakSelf initializationSuccess];
            } else {
                // call init callback delegate failed
                [weakSelf initializationFailure];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");

    initState = INIT_STATE_SUCCESS;
    
    // set mediation service
    [FBAdSettings setMediationService:[self getMediationService]];

    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(@"");

    initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackFailed:@"Meta SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];
    
    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:kMetaDataMixAudienceKey
                                       andValue:formattedValue]) {
        [self setMixedAudience:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setMixedAudience:(BOOL)isMixedAudience {
    LogAdapterApi_Internal(@"isMixedAudience = %@", isMixedAudience ? @"YES" : @"NO");
    [FBAdSettings setMixedAudience:isMixedAudience];
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (NSDictionary *)getBiddingData {
    if (initState == INIT_STATE_FAILED) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        return nil;
    }
    
    NSString *bidderToken = [FBAdSettings bidderToken];
    NSString *returnedToken = bidderToken ? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}


- (NSString *)getMediationService {
    if (!_mediationService) {
        _mediationService = [NSString stringWithFormat:@"%@_%@:%@", kMediationName, [IronSource sdkVersion], FacebookAdapterVersion];
        LogAdapterApi_Internal(@"mediationService = %@", _mediationService);
    }
    
    return _mediationService;
}

@end
