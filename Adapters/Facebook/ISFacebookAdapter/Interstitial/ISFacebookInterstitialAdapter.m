//
//  ISFacebookInterstitialAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import "ISFacebookInterstitialAdapter.h"
#import "ISFacebookInterstitialDelegate.h"

@interface ISFacebookInterstitialAdapter ()

@property (nonatomic, weak) ISFacebookAdapter   *adapter;

@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToAd;

@end

@implementation ISFacebookInterstitialAdapter

- (instancetype)initWithFacebookAdapter:(ISFacebookAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                                  = adapter;
        _adUnitPlacementIdToSmashDelegate         = [ISConcurrentMutableDictionary dictionary];
        _adUnitPlacementIdToAdDelegate            = [ISConcurrentMutableDictionary dictionary];
        _adUnitPlacementIdToAd                    = [ISConcurrentMutableDictionary dictionary];
    }
    return self;
}

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
    
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    NSString *allPlacementIds = [self getStringValueFromAdapterConfig:adapterConfig
                                                               forKey:kAllPlacementIds];

    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self.adapter isConfigValueValid:allPlacementIds]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    //add to interstitial delegate map
    [self.adUnitPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithPlacementIds:allPlacementIds];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Meta SDK init failed"}];
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    [self loadInterstitialInternal:adapterConfig
                          delegate:delegate
                        serverData:serverData];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    [self loadInterstitialInternal:adapterConfig
                          delegate:delegate
                        serverData:nil];
}

- (void)loadInterstitialInternal:(ISAdapterConfig *)adapterConfig
                  delegate:(id<ISInterstitialAdapterDelegate>)delegate
                      serverData:(NSString *)serverData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                               forKey:kPlacementId];
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        
        @try {
            // add delegate to dictionary
            [self.adUnitPlacementIdToSmashDelegate setObject:delegate
                                                      forKey:placementId];
            
            ISFacebookInterstitialDelegate *interstitialAdDelegate = [[ISFacebookInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                                                     andDelegate:delegate];
            [self.adUnitPlacementIdToAdDelegate setObject:interstitialAdDelegate
                                                   forKey:placementId];

            FBInterstitialAd *ad = [[FBInterstitialAd alloc] initWithPlacementID:placementId];
            ad.delegate = interstitialAdDelegate;
            
            [self.adUnitPlacementIdToAd setObject:ad
                                           forKey:placementId];
            
            if (serverData == nil) {
                [ad loadAd];
            } else {
                [ad loadAdWithBidPayload:serverData];
            }
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:exception.description}];
            [delegate adapterInterstitialInitFailedWithError:error];
        }
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                               forKey:kPlacementId];
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        
        @try {
            
            if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
                FBInterstitialAd *ad = [self.adUnitPlacementIdToAd objectForKey:placementId];
                [ad showAdFromRootViewController:viewController];
                
            } else {
                NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                          withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
                [delegate adapterInterstitialInitFailedWithError:error];
            }
            
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:exception.description}];
            [delegate adapterInterstitialInitFailedWithError:error];
        }
        
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    FBInterstitialAd *ad = [self.adUnitPlacementIdToAd objectForKey:placementId];
    return ad.adValid;
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                       adData:(NSDictionary *)adData {
    LogAdapterApi_Internal(@"");
    return [self.adapter getBiddingData];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    NSArray *placementIds = self.adUnitPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in placementIds) {
        id<ISInterstitialAdapterDelegate> delegate = [self.adUnitPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    NSArray *placementIds = self.adUnitPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in placementIds) {
        id<ISInterstitialAdapterDelegate> delegate = [self.adUnitPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // there is no required implementation for Meta release memory
}

@end
