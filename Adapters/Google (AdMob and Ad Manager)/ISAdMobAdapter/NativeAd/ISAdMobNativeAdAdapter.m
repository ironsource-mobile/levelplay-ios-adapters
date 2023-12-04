//
//  ISAdMobNativeAdAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import "ISAdMobNativeAdAdapter.h"
#import "ISAdMobNativeAdDelegate.h"
#import "ISAdMobConstants.h"
#import "ISAdMobAdapter+Internal.h"

@interface ISAdMobNativeAdAdapter ()

@property (nonatomic, weak) ISAdMobAdapter *adapter;

@property (nonatomic, weak) id<ISNativeAdAdapterDelegate> adUnitIdToSmashDelegate;
@property (nonatomic, strong) ISAdMobNativeAdDelegate *adUnitIdToAdDelegate;

// You must keep a strong reference to the GADAdLoader during the ad loading process.
@property (nonatomic, strong) GADAdLoader *nativeAdLoader;

@end

@implementation ISAdMobNativeAdAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                                = adapter;
        _adUnitIdToSmashDelegate                = nil;
        _adUnitIdToAdDelegate                   = nil;
    }
    return self;
}

#pragma mark - Native Ad API

- (void)initNativeAdsWithUserId:(NSString *)userId
                  adapterConfig:(ISAdapterConfig *)adapterConfig
                       delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    [self initNativeAdsInternalWithUserId:userId
                            adapterConfig:adapterConfig
                                 delegate:delegate];
}

- (void)initNativeAdForBiddingWithUserId:(NSString *)userId
                           adapterConfig:(ISAdapterConfig *)adapterConfig 
                                delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    [self initNativeAdsInternalWithUserId:userId
                            adapterConfig:adapterConfig
                                 delegate:delegate];
}

- (void)initNativeAdsInternalWithUserId:(NSString *)userId
                          adapterConfig:(ISAdapterConfig *)adapterConfig
                               delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
        
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterNativeAdInitFailedWithError:error];
        return;
    }
    
    self.adUnitIdToSmashDelegate = delegate;
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initAdMobSDKWithAdapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterNativeAdInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                  withMessage:@"AdMob SDK init failed"]];
            break;
        }
        case INIT_STATE_SUCCESS:
            [delegate adapterNativeAdInitSuccess];
            break;
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
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    //save reference to native ad delegate
    self.adUnitIdToSmashDelegate = delegate;

    dispatch_async(dispatch_get_main_queue(), ^{
        
        ISNativeAdProperties* nativeAdProperties = [super getNativeAdPropertiesWithAdapterConfig:adapterConfig];

        // creating ad options for AdMob
        ISAdOptionsPosition adOptionsPosition = nativeAdProperties.adOptionsPosition;
                       
        GADNativeAdViewAdOptions *nativeAdViewOptions = [[GADNativeAdViewAdOptions alloc] init];
        nativeAdViewOptions.preferredAdChoicesPosition = [self getAdChoicesPosition:adOptionsPosition];
        
        // initiating ad
        self.nativeAdLoader = [[GADAdLoader alloc] initWithAdUnitID: adUnitId
                                                 rootViewController: viewController
                                                            adTypes: @[GADAdLoaderAdTypeNative]
                                                            options: @[nativeAdViewOptions]];
        
        ISAdMobNativeAdDelegate *adMobDelegate = [[ISAdMobNativeAdDelegate alloc] initWithAdUnitId:adUnitId
                                                                                    viewController:viewController
                                                                                       andDelegate:delegate];
        //save reference for admob native ad delegate
        self.adUnitIdToAdDelegate = adMobDelegate;
        self.nativeAdLoader.delegate = adMobDelegate;

        // creating ad request
        GADRequest *request = [self.adapter createGADRequestForLoadWithAdData:adData
                                                                   serverData:serverData];
        
        // load request
        [self.nativeAdLoader loadRequest:request];
        
    });
}

- (void)destroyNativeAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    self.nativeAdLoader = nil;
    self.adUnitIdToSmashDelegate = nil;
    self.adUnitIdToAdDelegate = nil;
}

- (void)collectNativeAdBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                           delegate:(id<ISBiddingDataDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        GADRequest *request = [GADRequest request];
        request.requestAgent = kRequestAgent;
        NSMutableDictionary *additionalParameters = [[NSMutableDictionary alloc] init];
        additionalParameters[kAdMobQueryInfoType] = kAdMobRequesterType;

        GADExtras *extras = [[GADExtras alloc] init];
        extras.additionalParameters = additionalParameters;
        [request registerAdNetworkExtras:extras];
        
        [self.adapter collectBiddingDataWithAdData:request
                                          adFormat:GADAdFormatNative
                                          delegate:delegate];
    });
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.adUnitIdToSmashDelegate adapterNativeAdInitSuccess];
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    [self.adUnitIdToSmashDelegate adapterNativeAdInitFailedWithError:error];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    self.nativeAdLoader = nil;
    self.adUnitIdToSmashDelegate = nil;
    self.adUnitIdToAdDelegate = nil;
}

#pragma mark - Helpers

-(GADAdChoicesPosition) getAdChoicesPosition:(ISAdOptionsPosition)adOptionsPosition {
    switch (adOptionsPosition) {
        case ISAdOptionsPositionTopLeft:
            return GADAdChoicesPositionTopLeftCorner;
        case ISAdOptionsPositionTopRight:
            return GADAdChoicesPositionTopRightCorner;
        case ISAdOptionsPositionBottomLeft:
            return GADAdChoicesPositionBottomLeftCorner;
        case ISAdOptionsPositionBottomRight:
            return GADAdChoicesPositionBottomRightCorner;
    }
    
    return GADAdChoicesPositionBottomLeftCorner;
}

@end
