//
//  ISVerveAdapter.m
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISVerveAdapter.h"
#import "ISVerveConstants.h"
#import "ISVerveRewardedVideoAdapter.h"
#import "ISVerveInterstitialAdapter.h"
#import "ISVerveBannerAdapter.h"

#import <HyBid/HyBid.h>
#if __has_include(<HyBid/HyBid-Swift.h>)
    #import <HyBid/HyBid-Swift.h>
#else
    #import "HyBid-Swift.h"
#endif

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISVerveAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISVerveAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return VerveAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return HyBid.sdkVersion;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISVerveRewardedVideoAdapter *rewardedVideoAdapter = [[ISVerveRewardedVideoAdapter alloc] initWithVerveAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISVerveInterstitialAdapter *interstitialAdapter = [[ISVerveInterstitialAdapter alloc] initWithVerveAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        //Banner
        ISVerveBannerAdapter *bannerAdapter = [[ISVerveBannerAdapter alloc] initWithVerveAdapter:self];
        [self setBannerAdapter:bannerAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

- (void)initSDKWithAppToken:(NSString *)appToken {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"appToken = %@", appToken);
        
        initState = INIT_STATE_IN_PROGRESS;
        [HyBid initWithAppToken:appToken 
                     completion: ^(BOOL initSuccess){
            if(initSuccess) {
                [self initializationSuccess];
            }
            else {
                [self initializationFailure];
            }
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
        [initDelegate onNetworkInitCallbackFailed:@"Verve SDK init failed"];
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

- (void)setCCPAValue:(BOOL)value {
      LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    
      NSString *ccpaConsentString = value ? kMetaDataCCPAConsentValue : kMetaDataCCPANoConsentValue;
      [[HyBidUserDataManager sharedInstance] setIABUSPrivacyString:ccpaConsentString];
    
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    [HyBid setCoppa:value];
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *signal = [HyBid getCustomRequestSignalData:kMediation];
    if (signal && signal.length >= 0) {
        NSDictionary *biddingDataDictionary = @{kMediationTokenKey: signal};
        NSString *returnedToken = signal ?: @"";
        LogAdapterApi_Internal(@"%@ = %@", kMediationTokenKey, returnedToken);
        [delegate successWithBiddingData:biddingDataDictionary];
    }
    else{
        [delegate failureWithError:@"Token is nil or empty - Verve"];
    }
}

@end
