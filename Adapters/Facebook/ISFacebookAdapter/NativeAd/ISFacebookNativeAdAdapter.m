//
//  ISFacebookNativeAdAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import "ISFacebookNativeAdAdapter.h"
#import "ISFacebookNativeAdDelegate.h"
#import "ISFacebookConstants.h"
#import "ISFacebookAdapter+Internal.h"

@interface ISFacebookNativeAdAdapter ()

@property (nonatomic, weak) ISFacebookAdapter       *adapter;
@property (nonatomic, strong) FBNativeAd            *nativeAd;

@property (nonatomic, weak) id<ISNativeAdAdapterDelegate>     adUnitPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISFacebookNativeAdDelegate        *adUnitPlacementIdToAdDelegate;

@end

@implementation ISFacebookNativeAdAdapter

- (instancetype)initWithFacebookAdapter:(ISFacebookAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                                        = adapter;
        _adUnitPlacementIdToSmashDelegate               = nil;
        _adUnitPlacementIdToAdDelegate                  = nil;
    }
    return self;
}

#pragma mark - Native Ad API

- (void)initNativeAdsWithUserId:(NSString *)userId
                  adapterConfig:(ISAdapterConfig *)adapterConfig
                       delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    [self initNativeAdForBiddingWithUserId:userId
                             adapterConfig:adapterConfig
                                  delegate:delegate];
}

- (void)initNativeAdForBiddingWithUserId:(NSString *)userId
                           adapterConfig:(ISAdapterConfig *)adapterConfig
                                delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    NSString *allPlacementIds = [self getStringValueFromAdapterConfig:adapterConfig
                                                               forKey:kAllPlacementIds];
    
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterNativeAdInitFailedWithError:error];
        return;
    }
    
    if (![self.adapter isConfigValueValid:allPlacementIds]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterNativeAdInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    self.adUnitPlacementIdToSmashDelegate = delegate;
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithPlacementIds:allPlacementIds];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterNativeAdInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Meta SDK init failed"}];
            [delegate adapterNativeAdInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadNativeAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                               adData:(NSDictionary *)adData
                       viewController:(UIViewController *)viewController
                             delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    
    [self loadNativeAdInternalWithAdapterConfig:adapterConfig
                                         adData:adData
                                     serverData:nil
                                 viewController:viewController
                                       delegate:delegate];
}

- (void)loadNativeAdForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                         adData:(NSDictionary *)adData
                                     serverData:(NSString *)serverData
                                 viewController:(UIViewController *)viewController
                                       delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    
    [self loadNativeAdInternalWithAdapterConfig:adapterConfig
                                         adData:adData
                                     serverData:serverData
                                 viewController:viewController
                                       delegate:delegate];
}

- (void)loadNativeAdInternalWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                     delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];

    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    //save reference to native ad delegate
    self.adUnitPlacementIdToSmashDelegate = delegate;

    dispatch_async(dispatch_get_main_queue(), ^{
        
        ISNativeAdProperties* nativeAdProperties = [super getNativeAdPropertiesWithAdapterConfig:adapterConfig];

        // creating ad options for facebook
        ISAdOptionsPosition adOptionsPosition = nativeAdProperties.adOptionsPosition;

        // initiating ad
        self.nativeAd = [[FBNativeAd alloc] initWithPlacementID: placementId];
        
        
        ISFacebookNativeAdDelegate *facebookDelegate = [[ISFacebookNativeAdDelegate alloc] initWithPlacementId:placementId
                                                                                             adOptionsPosition:adOptionsPosition
                                                                                                viewController:viewController
                                                                                                      delegate:delegate];
        
        //save reference to facebook native ad delegate
        self.adUnitPlacementIdToAdDelegate = facebookDelegate;
        self.nativeAd.delegate = facebookDelegate;
     
        // load ad
        if (serverData == nil) {
            [self.nativeAd loadAd];
        } else {
            [self.nativeAd loadAdWithBidPayload:serverData];
        }
    });
}

- (void)destroyNativeAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    [self.nativeAd unregisterView];
    self.nativeAd = nil;
    self.adUnitPlacementIdToSmashDelegate = nil;
    self.adUnitPlacementIdToAdDelegate = nil;
}

- (NSDictionary *)getNativeAdBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   adData:(NSDictionary *)adData {
    return [self.adapter getBiddingData];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.adUnitPlacementIdToSmashDelegate adapterNativeAdInitSuccess];
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    [self.adUnitPlacementIdToSmashDelegate adapterNativeAdInitFailedWithError:error];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // there is no required implementation for Facebook release memory
}


@end
