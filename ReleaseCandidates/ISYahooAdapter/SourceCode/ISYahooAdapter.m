//
//  ISYahooAdapter.m
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 20/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISYahooAdapter.h"
#import "ISYahooRewardedVideoListener.h"
#import "ISYahooInterstitialListener.h"
#import "ISYahooBannerListener.h"
#import <VerizonAdsCore/VerizonAdsCore.h>
#import <VerizonAdsInterstitialPlacement/VerizonAdsInterstitialPlacement.h>
#import <VerizonAdsInlinePlacement/VerizonAdsInlinePlacement.h>

typedef NS_ENUM(NSInteger, InitState) {
    NO_INIT,
    INIT_IN_PROGRESS,
    INIT_SUCCESS,
    INIT_FAILED
};

static NSString * const kAdapterVersion              = YahooAdapterVersion;
static NSString * const kAdapterName                 = @"Yahoo";
static NSString * const kYahooCoppa                  = @"yahoo_coppa";
static NSString * const kYahooGDPR                   = @"yahoo_gdprconsent";
static NSString * const kSiteId                      = @"siteId";
static NSString * const kPlacementId                 = @"placementId";
static NSString * const kYahooServerDataWaterfallval = @"waterfallprovider/sideloading";
static NSString * const kYahooServerDataWaterfallKey = @"overrideWaterfallProvider";
static NSString * const kYahooServerDataISIdentifier = @"IronSourceVAS";
static NSString * const kYahooServerDataAdContent    = @"adContent";
static NSString * const kMissingErrorInfoMessage     = @"error reason is not available - VASErrorInfo is nil";
static NSString * const kYahooStringForDomain        = @"com.verizon.ads";
static NSString * const kYahooKeyForDomain           = @"editionVersion";


static InitState initState = NO_INIT;
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static VASDataPrivacyBuilder *privacyBuilder = nil;

@interface ISYahooAdapter () <ISYahooRewardedVideoDelegateWrapper, ISYahooInterstitialDelegateWrapper, ISYahooBannerDelegateWrapper, ISNetworkInitCallbackProtocol>

@property (nonatomic,strong) ConcurrentMutableDictionary *placementIdToRewardedVideoSmashDelegate;
@property (nonatomic,strong) ConcurrentMutableDictionary *placementIdToRewardedVideoAdListener;
@property (nonatomic,strong) ConcurrentMutableDictionary *placementIdToRewardedVideoAd;
@property (nonatomic,strong) ConcurrentMutableDictionary *rewardedVideoAdAvailability;

@property (nonatomic,strong) ConcurrentMutableDictionary *placementIdToInterstitialSmashDelegate;
@property (nonatomic,strong) ConcurrentMutableDictionary *placementIdToInterstitialAdListener;
@property (nonatomic,strong) ConcurrentMutableDictionary *placementIdToInterstitialAd;
@property (nonatomic,strong) ConcurrentMutableDictionary *interstitialAdAvailability;

@property (nonatomic,strong) ConcurrentMutableDictionary *placementIdToBannerSmashDelegate;
@property (nonatomic,strong) ConcurrentMutableDictionary *PlacementIdToBannerAdListener;
@property (nonatomic,strong) UIViewController *bannerViewController;

@end

@implementation ISYahooAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        // rewrded video
        _placementIdToRewardedVideoSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _placementIdToRewardedVideoAdListener = [ConcurrentMutableDictionary dictionary];
        _placementIdToRewardedVideoAd = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdAvailability = [ConcurrentMutableDictionary dictionary];
        
        // interstitial
        _placementIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _placementIdToInterstitialAdListener = [ConcurrentMutableDictionary dictionary];
        _placementIdToInterstitialAd = [ConcurrentMutableDictionary dictionary];
        _interstitialAdAvailability = [ConcurrentMutableDictionary dictionary];
        
        // banner
        _placementIdToBannerSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _PlacementIdToBannerAdListener = [ConcurrentMutableDictionary dictionary];
        _bannerViewController = nil;
        
        //LWS support
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
        
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        if(privacyBuilder == nil){
            privacyBuilder = [VASDataPrivacyBuilder new];
        }
        
        
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version{
    return kAdapterVersion;
}

- (NSString *)sdkVersion{
    return [[[VASAds sharedInstance] configuration] stringForDomain:kYahooStringForDomain key:kYahooKeyForDomain withDefault:@"N/A"];
}

- (NSArray *)systemFrameworks{
    return @[];
}

- (NSString *)sdkName{
    return kAdapterName;
}

- (void)setMetaDataWithKey:(NSString *)key andValues:(NSMutableArray *)values{
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"setMetaData: key=%@, value=%@", key, value);
    
    //set CCPA
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
        return;
    }
    
    //set COPPA
    if ([self isValidCCOPPAValue:value key:[key lowercaseString]]) {
        [self setCOPPAValue:[ISMetaDataUtils getCCPABooleanValue:[ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)]]];
        return;
    }
    
    //set GDPR - we allow any value to be sent without validation
    if ([self isValidGDPRAValue:value key:[key lowercaseString]]) {
        [self setGDPRAValue:value];
    }
}

- (void) setCCPAValue:(BOOL)value{
    LogAdapterApi_Internal(@"CCPA value = %@", value ? @"YES" : @"NO");
    privacyBuilder.ccpa.privacy = (value) ? @"1-Y-" : @"1-N-";
}

- (void) setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"is COPPA = %@", value ? @"YES" : @"NO");
    privacyBuilder.coppa.applies = value;
}

- (void) setGDPRAValue:(NSString*)value {
    LogAdapterApi_Internal(@"userConsent = %@", value);
    //set GDPR
    privacyBuilder.gdpr.consent = value;
    //set scope GDPR
    privacyBuilder.gdpr.scope = YES;
}

- (BOOL) isValidCCOPPAValue:(NSString*)value key: (NSString*) key {
    NSString *formattedValue = [ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)];
    return ([key isEqualToString:kYahooCoppa] && (formattedValue.length > 0));
}

- (BOOL) isValidGDPRAValue:(NSString*)value key: (NSString*) key {
    return ([key isEqualToString:kYahooGDPR] && (value.length > 0));
}


#pragma mark - Rewarded Video

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate is nil");
        return;
    }
    
    NSString *siteId = adapterConfig.settings[kSiteId];
    
    // siteId validation
    if (![self isConfigValueValid:siteId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSiteId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // placement validation
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    //add smash delegate to map
    [self.placementIdToRewardedVideoSmashDelegate setObject:delegate forKey:placementId];
    
    //init rewardedVideo
    switch (initState) {
        case INIT_SUCCESS: {
            [delegate adapterRewardedVideoInitSuccess] ;
        }
            break;
            
        case INIT_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"Yahoo SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed: error];
        }
            break;
            
        case INIT_IN_PROGRESS:
        case NO_INIT: {
            [self initSDKWithSiteId:siteId];
        }
            break;
    };
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    ISYahooRewardedVideoListener *rewardedVideoListener = [[ISYahooRewardedVideoListener alloc] initWithDelegate:self];
    
    [self.placementIdToRewardedVideoAdListener setObject:rewardedVideoListener forKey:placementId];
    
    VASInterstitialAdFactory* interstitialAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:placementId vasAds:[VASAds sharedInstance] delegate:rewardedVideoListener];
    
    //set server data and load ad with listener
    VASRequestMetadata* metaData = [self getLoadRequestMetaDataWithServerData:serverData];
    [interstitialAdFactory setRequestMetadata:metaData];
    [interstitialAdFactory load:rewardedVideoListener];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig{
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [self.rewardedVideoAdAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
    
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        //calls manipulating view objects needs to call from main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            //Show the ad
            [[self.placementIdToRewardedVideoAd objectForKey:placementId] showFromViewController:viewController];
        });
    } else{
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:@"No available ads"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
    
    [self.rewardedVideoAdAvailability setObject:@NO forKey:placementId];
    
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig{
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoLoadSuccess:(VASInterstitialAdFactory *)interstitialAdFactory interstitialAd:(VASInterstitialAd *)interstitialAd{
    NSString *placementId = interstitialAdFactory.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    [self.placementIdToRewardedVideoAd setObject:interstitialAd forKey:placementId];
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    [self.rewardedVideoAdAvailability setObject:@YES forKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)onRewardedVideoLoadFail:(VASInterstitialAdFactory *)interstitialAdFactory withError:(VASErrorInfo *)errorInfo {
    
    NSString *placementId = interstitialAdFactory.placementId;
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    [self.rewardedVideoAdAvailability setObject:@NO forKey:placementId];
    
    if (errorInfo == nil) {
        return;
    }
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        [delegate adapterRewardedVideoDidFailToLoadWithError:[self checkAndReturnLoadError:errorInfo noFillErrorToCheck:ERROR_RV_LOAD_NO_FILL]];
    }
}

- (void)onRewardedVideoAdShown:(VASInterstitialAd *)interstitialAd {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)onRewardedVideoShowFailed:(VASInterstitialAd *)interstitialAd withError:(VASErrorInfo *)errorInfo {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        if (errorInfo != nil) {
            [delegate adapterRewardedVideoDidFailToShowWithError:errorInfo];
        }
        else{
            NSError *error = [NSError errorWithDomain:self.adapterName code:ERROR_CODE_GENERIC   userInfo:@{NSLocalizedDescriptionKey : @"rewarded video show failed"}];
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    }
}

- (void)onRewardedVideoAdClicked:(VASInterstitialAd *)interstitialAd {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)onRewardedVideoAdReceiveReward:(VASInterstitialAd *)interstitialAd{
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}

- (void)onRewardedVideoAdClosed:(VASInterstitialAd *)interstitialAd {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidEnd];
        [delegate adapterRewardedVideoDidClose];
    }
}

#pragma mark - Interstitial

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate{
    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *siteId = adapterConfig.settings[kSiteId];
    
    // siteId validation
    if (![self isConfigValueValid:siteId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:siteId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // placement validation
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"%@ = %@",kPlacementId, placementId);
    
    //add smash delegate to map
    [self.placementIdToInterstitialSmashDelegate setObject:delegate forKey:placementId];
    
    //init Interstitials
    switch (initState) {
        case INIT_SUCCESS: {
            [delegate adapterInterstitialInitSuccess] ;
        }
            break;
            
        case INIT_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"Yahoo SDK init failed"}];
            [delegate adapterInterstitialInitFailedWithError: error];
        }
            break;
            
        case INIT_IN_PROGRESS:
        case NO_INIT: {
            [self initSDKWithSiteId:siteId];
        }
            break;
    };
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate{
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    LogInternal_Internal(@"%@ = %@",kPlacementId, placementId);
    
    ISYahooInterstitialListener * interstitialLoadListener = [[ISYahooInterstitialListener alloc] initWithDelegate:self];
    
    [self.placementIdToInterstitialAdListener setObject:interstitialLoadListener forKey:placementId];
    
    VASInterstitialAdFactory* interstitialAdFactory = [[VASInterstitialAdFactory alloc] initWithPlacementId:placementId vasAds:[VASAds sharedInstance] delegate:interstitialLoadListener];
    
    //set server data and load ad with listener
    VASRequestMetadata* metaData = [self getLoadRequestMetaDataWithServerData:serverData];
    [interstitialAdFactory setRequestMetadata:metaData];
    [interstitialAdFactory load:interstitialLoadListener];
}

-(void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate{
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        //calls manipulating view objects needs to call from main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            //Show the ad
            [[self.placementIdToInterstitialAd objectForKey:placementId] showFromViewController:viewController];
        });
        
    } else{
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:@"No available ads"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
    
    [self.interstitialAdAvailability setObject:@NO forKey:placementId];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig{
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [self.interstitialAdAvailability objectForKey:placementId];
    return (placementId != nil) && [available boolValue];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig{
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialLoadSuccess:(VASInterstitialAdFactory *)interstitialAdFactory InterstitialAd:(VASInterstitialAd *)interstitialAd{
    NSString *placementId = interstitialAdFactory.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    [self.placementIdToInterstitialAd setObject:interstitialAd forKey:placementId];
    [self.interstitialAdAvailability setObject:@YES forKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)onInterstitialLoadFail:(VASInterstitialAdFactory *)interstitialAdFactory withError:(VASErrorInfo *)errorInfo {
    NSString *placementId = interstitialAdFactory.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    [self.interstitialAdAvailability setObject:@NO forKey:placementId];
    
    if (delegate) {
        if (errorInfo != nil) {
            [delegate adapterInterstitialDidFailToLoadWithError:[self checkAndReturnLoadError:errorInfo noFillErrorToCheck:ERROR_IS_LOAD_NO_FILL]];
        }
        else{
            NSError *error = [NSError errorWithDomain:self.adapterName code:ERROR_CODE_GENERIC   userInfo:@{NSLocalizedDescriptionKey : @"load interstitial failed"}];
            [delegate adapterInterstitialDidFailToLoadWithError:error];
        }
    }
}

- (void)onInterstitialAdShown:(VASInterstitialAd *)interstitialAd {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialShowFailed:(VASInterstitialAd *)interstitialAd withError:(VASErrorInfo *)errorInfo {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        if (errorInfo != nil) {
            [delegate adapterInterstitialDidFailToShowWithError:errorInfo];
        }
        else{
            NSError *error = [NSError errorWithDomain:self.adapterName code:ERROR_CODE_GENERIC   userInfo:@{NSLocalizedDescriptionKey : @"interstitial show failed"}];
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    }
}

- (void)onInterstitialAdClicked:(VASInterstitialAd *)interstitialAd {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)onInterstitialAdClosed:(VASInterstitialAd *)interstitialAd {
    NSString *placementId = interstitialAd.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Banner
- (void)initBannerForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate{
    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *siteId = adapterConfig.settings[kSiteId];
    
    // siteId validation
    if (![self isConfigValueValid:siteId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:siteId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // placement validation
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    LogAdapterApi_Internal(@"%@ = %@",kPlacementId, placementId);
    
    //add smash delegate to map
    [self.placementIdToBannerSmashDelegate setObject:delegate forKey:placementId];
    
    //init banners
    switch (initState) {
        case INIT_SUCCESS: {
            [delegate adapterBannerInitSuccess] ;
        }
            break;
            
        case INIT_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"Yahoo SDK init failed"}];
            [delegate adapterBannerInitFailedWithError: error];
        }
            break;
            
        case INIT_IN_PROGRESS:
        case NO_INIT: {
            [self initSDKWithSiteId:siteId];
        }
            break;
    };
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData viewController:(UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate{
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    ISYahooBannerListener* yahooBannerAdListener = [[ISYahooBannerListener alloc] initWithDelegate:self];
    
    [self.PlacementIdToBannerAdListener setObject:yahooBannerAdListener forKey:placementId];
    
    VASInlineAdFactory* inlineAdFactory = [[VASInlineAdFactory alloc] initWithPlacementId:placementId adSizes:[self getBannerSize:size] vasAds:[VASAds sharedInstance] delegate:yahooBannerAdListener];
    
    //hold view controller in a property to return it in Yahoo׳s callback
    _bannerViewController = (viewController != nil) ? viewController : [self topMostController];
    
    //set server data and load ad with listener
    VASRequestMetadata* metaData = [self getLoadRequestMetaDataWithServerData:serverData];
    [inlineAdFactory setRequestMetadata:metaData];
    [inlineAdFactory load:yahooBannerAdListener];
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate{
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig{
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self.placementIdToBannerSmashDelegate removeObjectForKey:placementId];
    [self.PlacementIdToBannerAdListener removeObjectForKey:placementId];
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig{
    return [self getBiddingData];
}

#pragma mark - Banner Delegate

- (void)onBannerAdLoaded:(VASInlineAdFactory *)inlineFactory inlineAdFactory:(VASInlineAdView *)inlineView {
    NSString *placementId = inlineFactory.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        //calls manipulating view objects needs to call from main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            inlineView.frame = CGRectMake(0, 0, inlineView.adSize.width, inlineView.adSize.height);
            [delegate adapterBannerDidLoad:inlineView];
        });
    }
}

- (void)onBannerDidShow:(VASInlineAdView *)inlineAdView{
    NSString *placementId = inlineAdView.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerDidShow];
    }
}

- (void)onBannerLoadFailed:(VASInlineAdFactory *)inlineAdFactory withError:(VASErrorInfo *)errorInfo {
    NSString *placementId = inlineAdFactory.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        if (errorInfo != nil) {
            [delegate adapterBannerDidFailToLoadWithError:[self checkAndReturnLoadError:errorInfo noFillErrorToCheck:ERROR_BN_LOAD_NO_FILL]];
        }
        else{
            NSError *error = [NSError errorWithDomain:self.adapterName code:ERROR_CODE_GENERIC   userInfo:@{NSLocalizedDescriptionKey : @"load banner failed"}];
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    }
}

- (void)onBannerClicked:(VASInlineAdView *)inlineAdView {
    NSString *placementId = inlineAdView.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

- (void)onBannerDidLeaveApplication:(VASInlineAdView *)inlineAdView {
    NSString *placementId = inlineAdView.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

- (void)onBannerAdExpended:(VASInlineAdView *)inlineAdView {
    NSString *placementId = inlineAdView.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerWillPresentScreen];
    }
}

- (void)onBannerAdCollapse:(VASInlineAdView *)inlineAdView {
    NSString *placementId = inlineAdView.placementId;
    LogAdapterDelegate_Internal(@"placementId = %@",placementId);

    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerDidDismissScreen];
    }
}


- (UIViewController *)onBannerPresenting {
    return _bannerViewController;
}

#pragma mark - Init Delegates

- (void)onNetworkInitCallbackSuccess{
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _placementIdToRewardedVideoSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_placementIdToRewardedVideoSmashDelegate hasObjectForKey:placementId])
        {
            [[_placementIdToRewardedVideoSmashDelegate objectForKey:placementId] adapterRewardedVideoInitSuccess];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _placementIdToInterstitialSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        if ([_placementIdToInterstitialSmashDelegate hasObjectForKey:placementId])
        {
            [[_placementIdToInterstitialSmashDelegate objectForKey:placementId] adapterInterstitialInitSuccess];
        }
    }
    
    // banner
    NSArray *bannerPlacementIDs = _placementIdToBannerSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        if([_placementIdToBannerSmashDelegate hasObjectForKey:placementId])
        {
            [[_placementIdToBannerSmashDelegate objectForKey:placementId] adapterBannerInitSuccess];
        }
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage{
    
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    NSArray *rewardedVideoPlacementIDs = _placementIdToRewardedVideoSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_placementIdToRewardedVideoSmashDelegate hasObjectForKey:placementId])
        {
            [[_placementIdToRewardedVideoSmashDelegate objectForKey:placementId] adapterRewardedVideoInitFailed:error];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _placementIdToInterstitialSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        if ([_placementIdToInterstitialSmashDelegate hasObjectForKey:placementId])
        {
            [[_placementIdToInterstitialSmashDelegate objectForKey:placementId] adapterInterstitialInitFailedWithError:error];
        }
    }
    
    // banner
    NSArray *bannerPlacementIDs = _placementIdToBannerSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        if([_placementIdToBannerSmashDelegate hasObjectForKey:placementId])
        {
            [[_placementIdToBannerSmashDelegate objectForKey:placementId] adapterBannerInitFailedWithError:error];
        }
    }
}

- (void)onNetworkInitCallbackLoadSuccess:(NSString *)placement{    
}

#pragma mark - Helper Methods

- (void)initSDKWithSiteId:(NSString *)siteId {
    LogAdapterDelegate_Info(@"%@ = %@",kSiteId, siteId);
    
    if(initState == NO_INIT || initState == INIT_IN_PROGRESS){
        [initCallbackDelegates addObject:self];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //init needs to be called from main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            initState = INIT_IN_PROGRESS;
            
            //set adapter debug level
            ([ISConfigurations getConfigurations].adaptersDebug) ? [VASAds setLogLevel:VASLogLevelDebug] : [VASAds setLogLevel:VASLogLevelInfo];
            
            NSArray *initDelegatesList = initCallbackDelegates.allObjects;
            
            //set privacy data
            [[VASAds sharedInstance] setDataPrivacy:[privacyBuilder build]];
            
            if([VASAds initializeWithSiteId:siteId]){
                initState = INIT_SUCCESS;
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
                    [initDelegate onNetworkInitCallbackSuccess];
                }
            }
            else{
                initState = INIT_FAILED;
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
                    [initDelegate onNetworkInitCallbackFailed:@"FAILED - Yahoo SDK failed to init"];
                    
                }
            }
            [initCallbackDelegates removeAllObjects];
        });
    });
}

- (NSDictionary *)getBiddingData {
    
    if (initState != INIT_SUCCESS) {
        LogAdapterApi_Internal(@"returning nil as token since init isn't completed");
        return nil;
    }
    
    NSString *bidderToken = [[VASAds sharedInstance] biddingTokenTrimmedToSize:0];
    LogAdapterApi_Internal(@"token = %@", bidderToken);
    
    return @{@"token": bidderToken};
}

- (NSArray *)getBannerSize:(ISBannerSize *)size {
    VASInlineAdSize *bannerSize = [VASInlineAdSize alloc];
    NSArray<VASInlineAdSize*> *arrayBannerSize;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        bannerSize = [bannerSize initWithWidth:320 height:50];
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        bannerSize = [bannerSize initWithWidth:300 height:250];
    }
    else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        bannerSize = [bannerSize initWithWidth:320 height:90];
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        bannerSize = ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) ? [bannerSize initWithWidth:728 height:90] : [bannerSize initWithWidth:320 height:50];
    }
    else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        bannerSize = [bannerSize initWithWidth:size.width height:size.height];
    }
    
    arrayBannerSize = [[NSArray alloc] initWithObjects:bannerSize, nil];
    return arrayBannerSize;
}

-(VASRequestMetadata *)getLoadRequestMetaDataWithServerData:(NSString*) serverData{
    NSMutableDictionary<NSString *, id> *placementData = [NSMutableDictionary dictionaryWithDictionary: @{kYahooServerDataAdContent : serverData ,kYahooServerDataWaterfallKey: kYahooServerDataWaterfallval}];
    VASRequestMetadataBuilder *metadataBuilder = [[VASRequestMetadataBuilder alloc] initWithRequestMetadata:[VASAds sharedInstance].requestMetadata];
    //add ironsource identifier and sdk version to bid requests
    [metadataBuilder setMediator: [NSString stringWithFormat:@"%@ %@",kYahooServerDataISIdentifier, kAdapterVersion]];
    [metadataBuilder setPlacementData:placementData];
    return metadataBuilder.build;
}

-(NSError *)checkAndReturnLoadError:(VASErrorInfo *) errorInfo noFillErrorToCheck:(ISErrorCode) isError{
    
    if (errorInfo.code == VASCoreErrorAdPrepareFailure) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:isError userInfo:@{NSLocalizedDescriptionKey:errorInfo.description}];
        return error;
    }
    return errorInfo;
}

@end
