//
//  ISAdMobAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import "ISAdMobAdapter.h"
#import "ISAdMobRewardedVideoAdapter.h"
#import "ISAdMobInterstitialAdapter.h"
#import "ISAdMobBannerAdapter.h"
#import "ISAdMobConstants.h"
#import "ISAdMobNativeAdAdapter.h"

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState initState = INIT_STATE_NONE;

// Consent flags
static BOOL _didSetConsentCollectingUserData      = NO;
static BOOL _consentCollectingUserData            = NO;
static NSString *contentMappingURLValue           = @"";
static NSArray *neighboringContentMappingURLValue = nil;

@interface ISAdMobAdapter () <ISNetworkInitCallbackProtocol>

@end

@implementation ISAdMobAdapter


#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return AdMobAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return GADGetStringFromVersionNumber(GADMobileAds.sharedInstance.versionNumber);
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded Video
        ISAdMobRewardedVideoAdapter *rewardedVideoAdapter = [[ISAdMobRewardedVideoAdapter alloc] initWithAdMobAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];
        
        // Interstitial
        ISAdMobInterstitialAdapter *InterstitialAdapter = [[ISAdMobInterstitialAdapter alloc] initWithAdMobAdapter:self];
        [self setInterstitialAdapter:InterstitialAdapter];

        // Banner
        ISAdMobBannerAdapter *bannerAdapter = [[ISAdMobBannerAdapter alloc] initWithAdMobAdapter:self];
        [self setBannerAdapter:bannerAdapter];

        // NativeAd
        ISAdMobNativeAdAdapter *nativeAdAdapter = [[ISAdMobNativeAdAdapter alloc] initWithAdMobAdapter:self];
        [self setNativeAdAdapter:nativeAdAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initAdMobSDKWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // add self to init delegates only when init not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterDelegate_Internal(@"");
        
        initState = INIT_STATE_IN_PROGRESS;
        
        // In case the platform doesn't override this flag the default is to init only the network
        BOOL networkOnlyInit = adapterConfig.settings[kNetworkOnlyInitFlag] ? [adapterConfig.settings[kNetworkOnlyInitFlag] boolValue] : YES;
        
        if (networkOnlyInit) {
            LogAdapterDelegate_Internal(@"disableMediationInitialization");
            [[GADMobileAds sharedInstance] disableMediationInitialization];
        }
        
        // In case the platform doesn't override this flag the default is not to wait for the init callback before loading an ad
        BOOL shouldWaitForInitCallback = adapterConfig.settings[kInitResponseRequiredFlag] ? [adapterConfig.settings[kInitResponseRequiredFlag] boolValue] : NO;
        
        if (shouldWaitForInitCallback) {
            LogAdapterDelegate_Internal(@"init and wait for callback");
            
            ISAdMobAdapter * __weak weakSelf = self;
            [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *_Nonnull status) {
                
                __typeof__(self) strongSelf = weakSelf;
                
                NSDictionary *adapterStatuses = status.adapterStatusesByClassName;
                
                if ([adapterStatuses objectForKey:kAdMobNetworkId]) {
                    GADAdapterStatus *initStatus = [adapterStatuses objectForKey:kAdMobNetworkId];
                    
                    if (initStatus.state == GADAdapterInitializationStateReady) {
                        [strongSelf initializationSuccess];
                        return;
                    }
                }
                
                // If we got here then either the AdMob network is missing from the initalization status dictionary
                // or it returned as not ready
                [strongSelf initializationFailure];
            }];
        }
        else {
            LogAdapterDelegate_Internal(@"init without callback");
            [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
            [self initializationSuccess];
        }
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_SUCCESS;
    
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
        [initDelegate onNetworkInitCallbackFailed:@"AdMob SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"value = %@", consent? @"YES" : @"NO");
    _consentCollectingUserData = consent;
    _didSetConsentCollectingUserData = YES;
}

- (void)setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"key = %@ value = %@",kAdMobCCPAKey, value? @"YES" : @"NO");
    
    [NSUserDefaults.standardUserDefaults setBool:value
                                          forKey:kAdMobCCPAKey];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
    
    if (values.count > 1 && [key caseInsensitiveCompare:kAdMobContentMapping] == NSOrderedSame){
        // multiple URL
        neighboringContentMappingURLValue = values;
        LogAdapterApi_Internal(@"key = %@, values = %@", kAdMobContentMapping, values);
        return;
    }
    
    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
    } else {
        [self setAdMobMetaDataWithKey:[key lowercaseString]
                                value:[value lowercaseString]];
    }
}

- (void)setAdMobMetaDataWithKey:(NSString *)key
                          value:(NSString *)valueString {
    NSString *formattedValueString = valueString;
    
    if ([key isEqualToString:kAdMobTFCD] || [key isEqualToString:kAdMobTFUA]) {
        // Those of the AdMob MetaData keys accept only boolean values
        formattedValueString = [ISMetaDataUtils formatValue:valueString
                                                    forType:(META_DATA_VALUE_BOOL)];
        
        if (!formattedValueString.length) {
            LogAdapterApi_Internal(@"MetaData value for key %@ is invalid %@", key, valueString);
            return;
        }
    }
    
    if ([key isEqualToString:kAdMobTFCD]) {
        BOOL coppaValue = [ISMetaDataUtils getMetaDataBooleanValue:formattedValueString];
        LogAdapterApi_Internal(@"key = %@, coppaValue = %@", kAdMobTFCD, coppaValue? @"YES" : @"NO");
        GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @(coppaValue);
    } else if ([key isEqualToString:kAdMobTFUA]) {
        BOOL euValue = [ISMetaDataUtils getMetaDataBooleanValue:formattedValueString];
        LogAdapterApi_Internal(@"key = %@, euValue = %@", kAdMobTFUA, euValue? @"YES" : @"NO");
        GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent = @(euValue);
    } else if ([key isEqualToString:kAdMobContentRating]) {
        GADMaxAdContentRating ratingValue = [self getAdMobRatingValue:formattedValueString];
        if (ratingValue.length) {
            LogAdapterApi_Internal(@"key = %@, ratingValue = %@", kAdMobContentRating, formattedValueString);
            [GADMobileAds.sharedInstance.requestConfiguration setMaxAdContentRating: ratingValue];
        }
    } else if ([key caseInsensitiveCompare:kAdMobContentMapping] == NSOrderedSame) {
        contentMappingURLValue = valueString;
        LogAdapterApi_Internal(@"key = %@, contentMappingValue = %@", kAdMobContentMapping, valueString);
    }
}

-(GADMaxAdContentRating)getAdMobRatingValue:(NSString *)value {
    if (!value.length) {
        LogInternal_Error(@"The ratingValue is nil");
        return nil;
    }
    
    GADMaxAdContentRating contentValue = nil;
    
    if ([value isEqualToString:kAdMobMaxContentRatingG]) {
        contentValue = GADMaxAdContentRatingGeneral;
    } else if ([value isEqualToString:kAdMobMaxContentRatingPG]) {
        contentValue = GADMaxAdContentRatingParentalGuidance;
    } else if ([value isEqualToString:kAdMobMaxContentRatingT]) {
        contentValue = GADMaxAdContentRatingTeen;
    } else if ([value isEqualToString:kAdMobMaxContentRatingMA]) {
        contentValue = GADMaxAdContentRatingMatureAudience;
    } else {
        LogInternal_Error(@"The ratingValue = %@ is undefine", value);
    }
    
    return contentValue;
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (GADRequest *)createGADRequestForLoadWithAdData:(NSDictionary *)adData
                                       serverData:(NSString *)serverData {
    GADRequest *request = [GADRequest request];
    request.requestAgent = kRequestAgent;
    
    if (serverData.length) {
        request.adString = serverData;
    }
    
    NSMutableDictionary *additionalParameters = [[NSMutableDictionary alloc] init];
    additionalParameters[@"platform_name"] = kPlatformName;
    BOOL hybridMode = NO;
    
    if (adData) {
        NSString *requestId = [adData objectForKey:@"requestId"];
        hybridMode = [[adData objectForKey:@"isHybrid"] boolValue];
        
        if (requestId.length) {
            additionalParameters[@"placement_req_id"] = requestId;
            LogInternal_Internal(@"adData requestId = %@, isHybrid = %@", requestId, hybridMode? @"YES" : @"NO");
        }
    } else {
        LogInternal_Internal(@"adData is nil, using default hybridMode = NO");
    }
    
    additionalParameters[@"is_hybrid_setup"] = hybridMode? @"true" : @"false";
    
    if ([ISConfigurations getConfigurations].userAge > kMinUserAge) {
        BOOL tagForChildDirectedTreatment = [ISConfigurations getConfigurations].userAge < kMaxChildAge;
        LogAdapterApi_Internal(@"creating request with age = %ld tagForChildDirectedTreatment = %d", (long)[ISConfigurations getConfigurations].userAge, tagForChildDirectedTreatment);
        GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment = @(tagForChildDirectedTreatment);
    }
    
    if (_didSetConsentCollectingUserData && !_consentCollectingUserData) {
        // The default behavior of the Google Mobile Ads SDK is to serve personalized ads
        // If a user has consented to receive only non-personalized ads, you can configure an GADRequest object with the following code to specify that only non-personalized ads should be returned:
        additionalParameters[@"npa"] = @"1";
    }
    
    //handle single content mapping for ad request
    if(contentMappingURLValue.length){
        LogAdapterApi_Internal(@"contentMappingURLValue = %@", contentMappingURLValue);
        request.contentURL = contentMappingURLValue;
    }

    //handle neighboring content mapping for ad request
    if(neighboringContentMappingURLValue.count){
        LogAdapterApi_Internal(@"neighboringContentMappingURLValue = %@" , neighboringContentMappingURLValue);
        request.neighboringContentURLStrings = neighboringContentMappingURLValue;
    }
    
    GADExtras *extras = [[GADExtras alloc] init];
    extras.additionalParameters = additionalParameters;
    [request registerAdNetworkExtras:extras];
    
    return request;
}

- (void)collectBiddingDataWithAdData:(GADRequest *)request
                            adFormat:(GADAdFormat)adFormat
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    
    if (initState == INIT_STATE_NONE) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't started"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
            
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [GADQueryInfo createQueryInfoWithRequest:request
                                        adFormat:adFormat
                               completionHandler:^(GADQueryInfo *_Nullable queryInfo, NSError *_Nullable error) {
            
            if (error) {
                LogAdapterApi_Internal(@"%@", error.localizedDescription);
                [delegate failureWithError:error.localizedDescription];
                return;
            }
            
            if (!queryInfo) {
                [delegate failureWithError:@"queryInfo is nil"];
                return;
            }
            
            NSString *sdkVersion = [self sdkVersion];
            NSString *returnedToken = queryInfo.query? queryInfo.query : @"";
            LogAdapterApi_Internal(@"token = %@, sdkVersion = %@", returnedToken, sdkVersion);
            NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: returnedToken, @"token", sdkVersion, @"sdkVersion", nil];
            
            [delegate successWithBiddingData:biddingDataDictionary];
        }];
    });
}

@end
