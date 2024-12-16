//
//  ISBigoAdapter.m
//  ISBigoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//
#import "ISBigoAdapter.h"
#import "ISBigoConstants.h"
#import "ISBigoRewardedVideoAdapter.h"
#import "ISBigoInterstitialAdapter.h"
#import "ISBigoBannerAdapter.h"
#import <BigoADS/BigoAdSdk.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISBigoAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISBigoAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return BigoAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return BigoAdSdk.sharedInstance.getSDKVersionName;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISBigoRewardedVideoAdapter *rewardedVideoAdapter = [[ISBigoRewardedVideoAdapter alloc] initWithBigoAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISBigoInterstitialAdapter *interstitialAdapter = [[ISBigoInterstitialAdapter alloc] initWithBigoAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        //Banner
        ISBigoBannerAdapter *bannerAdapter = [[ISBigoBannerAdapter alloc] initWithBigoAdapter:self];
        [self setBannerAdapter:bannerAdapter];

        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (NSString *)getMediationInfo {
    NSDictionary *mediationInfoDict = @{@"mediationName" : @"LevelPlay",
                                        @"mediationVersion" : [IronSource sdkVersion],
                                        @"adapterVersion" : BigoAdapterVersion};
    
    NSError *error = nil;
    NSData *mediationInfoJSONData = [NSJSONSerialization dataWithJSONObject:mediationInfoDict options:0 error:&error];
    
    if (!error) {
        return [[NSString alloc] initWithData:mediationInfoJSONData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (void)initSDKWithAppKey:(NSString *)appKey {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"appKey = %@", appKey);
        
        initState = INIT_STATE_IN_PROGRESS;
        BigoAdConfig *adConfig = [[BigoAdConfig alloc] initWithAppId:appKey];
        [[BigoAdSdk sharedInstance] initializeSdkWithAdConfig:adConfig completion:^{
            [self initializationSuccess];
        }];
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
        [initDelegate onNetworkInitCallbackFailed:@"Bigo SDK init failed"];
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
    [BigoAdSdk setUserConsentWithOption: BigoConsentOptionsGDPR consent: consent];
}


- (void)setCCPAValue:(BOOL)do_not_sell {
    LogAdapterApi_Internal(@"value = %@", do_not_sell ? @"YES" : @"NO");
    [BigoAdSdk setUserConsentWithOption: BigoConsentOptionsCCPA consent: !do_not_sell];
}

- (void)setCOPPAValue:(BOOL)child_restricted {
    LogAdapterApi_Internal(@"value = %@", child_restricted ? @"YES" : @"NO");
    [BigoAdSdk setUserConsentWithOption: BigoConsentOptionsCOPPA consent: !child_restricted];
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    // After bigo ads sdk initialized.
    NSString *bidderToken = [[BigoAdSdk sharedInstance] getBidderToken];
    if (bidderToken == nil || [bidderToken isEqual: @""]) {
        [delegate failureWithError:@"Failed to get bidder token"];
    }
    NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: bidderToken, @"token", nil];
    [delegate successWithBiddingData:biddingDataDictionary];
}



@end
