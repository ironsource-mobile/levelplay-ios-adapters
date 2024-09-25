//
//  ISMobileFuseAdapter.m
//  ISMobileFuseAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//
#import "ISMobileFuseAdapter.h"
#import "ISMobileFuseConstants.h"
#import "ISMobileFuseRewardedVideoAdapter.h"
#import "ISMobileFuseInterstitialAdapter.h"
#import "ISMobileFuseBannerAdapter.h"

#import <MobileFuseSDK/MobileFuse.h>
#import <MobileFuseSDK/MobileFuseSettings.h>
#import <MobileFuseSDK/IMFAdCallbackReceiver.h>
#import <MobileFuseSDK/MFBiddingTokenProvider.h>
#import <MobileFuseSDK/MFInterstitialAd.h>
#import <MobileFuseSDK/MFBannerAd.h>
#import <MobileFuseSDK/MFRewardedAd.h>
#import <MobileFuseSDK/MFNativeAd.h>
#import <MobileFuseSDK/MobileFusePrivacyPreferences.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

// Privacy default values
static BOOL coppaValue = NO;
static BOOL doNotTrackValue = NO;
static NSString *doNotSellValue = @"1-";

@interface ISMobileFuseAdapter() <IMFInitializationCallbackReceiver, ISNetworkInitCallbackProtocol>

@end

@implementation ISMobileFuseAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return mobileFuseAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [MobileFuse version];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISMobileFuseRewardedVideoAdapter *rewardedVideoAdapter = [[ISMobileFuseRewardedVideoAdapter alloc] initWithMobileFuseAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISMobileFuseInterstitialAdapter *interstitialAdapter = [[ISMobileFuseInterstitialAdapter alloc] initWithMobileFuseAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        //Banner
        ISMobileFuseBannerAdapter *bannerAdapter = [[ISMobileFuseBannerAdapter alloc] initWithMobileFuseAdapter:self];
        [self setBannerAdapter:bannerAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

- (void)initSDKWithPlacementId:(NSString *)placementId{
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        initState = INIT_STATE_IN_PROGRESS;
        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [MobileFuse enableVerboseLogging];
        }
        [MobileFuse initWithDelegate:self];
    });
}

- (void)onInitSuccess:(NSString *)appId withPublisherId:(NSString *)publisherId {
    [self initializationSuccess];
}
- (void)onInitError:(NSString *)appId withPublisherId:(NSString *)publisherId withError:(MFAdError *)error {
    LogAdapterDelegate_Internal(@"error code = %ld, descrption = %@", (long)error.code, error.description);
    [self initializationFailure];
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
        [initDelegate onNetworkInitCallbackFailed:@"MobileFuse SDK init failed"];
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
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
        
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];
        
        if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                               flag:kMetaDataCOPPAKey
                                           andValue:value]) {
            [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
        }
    }
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent? @"YES" : @"NO");
    doNotTrackValue = consent ? NO : YES; // doNotTrack is opposite of consent
}

- (void)setCCPAValue:(BOOL)doNotSell {
    LogAdapterApi_Internal(@"ccpa = %@", doNotSell? @"YES" : @"NO");
    doNotSellValue = doNotSell ? KDoNotSellYesValue : KDoNotSellNoValue;

}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    coppaValue = value;
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (MobileFusePrivacyPreferences *)getPrivacyData {
    MobileFusePrivacyPreferences *privacyPreferences = [[MobileFusePrivacyPreferences alloc] init];
    [privacyPreferences setSubjectToCoppa:coppaValue];
    [privacyPreferences setDoNotTrack:doNotTrackValue];
    [privacyPreferences setUsPrivacyConsentString:doNotSellValue];
    return privacyPreferences;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    
    if (initState != INIT_STATE_SUCCESS) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't finished successfully"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    
    MFBiddingTokenRequest* request = [[MFBiddingTokenRequest alloc] init];
    request.privacyPreferences = [self getPrivacyData];

    [MFBiddingTokenProvider getTokenWithRequest: request withCallback:^(NSString *token) {

        if(token == nil || token.length == 0) {
            [delegate failureWithError:@"Failed to receive token - MobileFuse"];
            return;
        }

        NSString *returnedToken = token ? token : @"";
        LogAdapterApi_Internal(@"token = %@", returnedToken);
        NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: returnedToken, @"token", nil];
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
