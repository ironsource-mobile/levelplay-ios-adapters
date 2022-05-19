//
//  ISAPSAdapter.m
//  ISAPSAdapter
//
//  Created by Sveta Itskovich on 11/11/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISAPSAdapter.h"
#import "ISAPSInterstitialListener.h"
#import "ISAPSBannerListener.h"
#import "IronSource/ISSetAPSDataProtocol.h"
#import <DTBiOSSDK/DTBiOSSDK.h>

static NSString * const kAdapterVersion          = APSAdapterVersion;
static NSString * const kAdapterName             = @"APS";
static NSString * const kPlacementId             = @"placementId";
static NSString * const kUUID                    = @"uuid";
static NSString * const kPricePointEncoded       = @"pricePointEncoded";
static NSString * const kToken                   = @"token";
static NSString * const kWidth                   = @"width";
static NSString * const kHeight                  = @"height";
static NSString * const kMediationHints          = @"mediationHints";
static NSString * const kInterstitial            = @"interstitial";
static NSString * const kBanner                  = @"banner";

//Interstitial static memebers to share across the adapters
static ConcurrentMutableDictionary *interstitialAPSData = nil;
static ConcurrentMutableDictionary *interstitialTimestampToMediationHints = nil;

//Banner static memebers to share across the adapters
static ConcurrentMutableDictionary *bannerAPSData = nil;
static ConcurrentMutableDictionary *bannerTimestampToMediationHints = nil;

// synchronization lock
static NSObject                    *APSDataLock;

@interface ISAPSAdapter () <ISSetAPSDataProtocol, ISAPSISDelegateWrapper, ISAPSBNSDelegateWrapper>

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToInterstitialSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIDToInterstitialAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToInterstitialAPSListener;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToBannerSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToBannerAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToBannerAPSListener;

@end

@implementation ISAPSAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        // Interstitial
        _placementIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _placementIDToInterstitialAd = [ConcurrentMutableDictionary dictionary];
        _placementIdToInterstitialAPSListener = [ConcurrentMutableDictionary dictionary];
        if (!interstitialAPSData) {
            interstitialAPSData = [ConcurrentMutableDictionary dictionary];
        }
        if (!interstitialTimestampToMediationHints) {
            interstitialTimestampToMediationHints = [ConcurrentMutableDictionary dictionary];
        }
        
        // Banner
        _placementIdToBannerSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _placementIdToBannerAd = [ConcurrentMutableDictionary dictionary];
        _placementIdToBannerAPSListener = [ConcurrentMutableDictionary dictionary];
        if (!bannerAPSData) {
            bannerAPSData = [ConcurrentMutableDictionary dictionary];
        }
        if (!bannerTimestampToMediationHints) {
            bannerTimestampToMediationHints = [ConcurrentMutableDictionary dictionary];
        }
        
        if (!APSDataLock) {
            APSDataLock = [NSObject new];
        }
    }
    
    return self;
}


#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [DTBAds version];
}

- (NSArray *) systemFrameworks {
    return @[@"CoreTelephony",
             @"EventKit",
             @"EventKitUI",
             @"MediaPlayer",
             @"StoreKit",
             @"SystemConfiguration",
             @"QuartzCore"];
}

- (NSString *)sdkName {
    return kAdapterName;
}

- (void)setAPSDataWithAdUnit:(NSString *)adUnit apsData:(NSDictionary *)apsData {
    LogAdapterApi_Internal(@"");
    
    if (![adUnit isEqualToString:kInterstitial] && ![adUnit isEqualToString:kBanner]) {
        LogAdapterApi_Error(@"Unsupported adUnit %@", adUnit);
        return;
    }
    
    //Mandatory parameters
    NSString *uuid = [apsData objectForKey:kUUID];
    if (!uuid) {
        LogAdapterApi_Error(@"APSData is missing %@", kUUID);
        return;
    }
    
    NSString *pricePointEncoded = [apsData objectForKey:kPricePointEncoded];
    if (!pricePointEncoded) {
        LogAdapterApi_Error(@"APSData is missing %@", kPricePointEncoded);
        return;
    }
    
    NSDictionary *mediationHints = [apsData objectForKey:kMediationHints];
    if (!mediationHints) {
        LogAdapterApi_Error(@"APSData is missing  %@", kMediationHints);
        return;
    }
    
    NSNumber *width = [apsData objectForKey:kWidth];
    NSNumber *height = [apsData objectForKey:kHeight];
    
    //a random id to represent the bid info for the auctioneer
    NSString *token = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    ConcurrentMutableDictionary *apsDataDict = [adUnit isEqualToString:kBanner]? bannerAPSData : interstitialAPSData;
    
    @synchronized (APSDataLock) {
        [apsDataDict removeAllObjects];
        [apsDataDict setObject:uuid forKey:kUUID];
        [apsDataDict setObject:pricePointEncoded forKey:kPricePointEncoded];
        [apsDataDict setObject:mediationHints forKey:kMediationHints];
        [apsDataDict setObject:token forKey:kToken];
        
        if ([adUnit isEqualToString:kBanner] && width && height) {
            [apsDataDict setObject:width forKey:kWidth];
            [apsDataDict setObject:height forKey:kHeight];
        }
    }
}

#pragma mark - Interstitial API

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingDataForAuctioneer:interstitialAPSData andSaveMediationHints:interstitialTimestampToMediationHints];
}

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);
    
    [_placementIdToInterstitialSmashDelegate setObject:delegate forKey:placementID];
    ISAPSInterstitialListener *interstitialListener = [[ISAPSInterstitialListener alloc] initWithPlacementID:placementID andDelegate:self];
    [_placementIdToInterstitialAPSListener setObject:interstitialListener forKey:placementID];
    // Publishers are expected to iniitalize the APS SDK. We therefore have no init method and should just return init success for the mediation to proceed as expected
    [delegate adapterInterstitialInitSuccess];
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);
    
    if (!serverData.length) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey:@"APS server data is empty"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    NSDictionary* mediationHints = nil;
    
    @synchronized (APSDataLock) {
        // The auctioneer returns the timestamp we sent them as the server data
        if (![interstitialTimestampToMediationHints hasObjectForKey:serverData]) {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:@"APS server data is invalid"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToLoadWithError:error];
            return;
        }
        
        mediationHints = [interstitialTimestampToMediationHints objectForKey:serverData];
        // We are expected to use the mediation hints only once and therefore should remove it upon extraction of the data
        [interstitialTimestampToMediationHints removeObjectForKey:serverData];
    }
    
    //create APS ad
    dispatch_async(dispatch_get_main_queue(), ^{
        ISAPSInterstitialListener *interstitialListener = [self.placementIdToInterstitialAPSListener objectForKey:placementID];
        DTBAdInterstitialDispatcher *dispatcher = [[DTBAdInterstitialDispatcher alloc] initWithDelegate:interstitialListener];
        [self.placementIDToInterstitialAd setObject:dispatcher forKey:placementID];
        [dispatcher fetchAdWithParameters:mediationHints];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementID = %@", placementId);
    DTBAdInterstitialDispatcher *interstitialAd = [self.placementIDToInterstitialAd objectForKey:placementId];
    return (interstitialAd != nil) && interstitialAd.interstitialLoaded;
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    LogAdapterApi_Internal(@"placementID = %@", placementId);
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DTBAdInterstitialDispatcher *interstitialAd = [self.placementIDToInterstitialAd objectForKey:placementId];
            [interstitialAd showFromController:viewController];
        });
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:@"APS showInterstitialWithViewController"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
}

#pragma mark - Interstitial Delegate

- (void)interstitialDidLoad:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)interstitial:(NSString *)placementId didFailToLoadAdWithErrorCode:(DTBAdErrorCode)errorCode {
    LogAdapterDelegate_Internal(@"placementId = %@ errorCode = %d", placementId, (int) errorCode);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        NSInteger isErrorCode = (errorCode == SampleErrorCodeNoInventory) ? ERROR_IS_LOAD_NO_FILL : errorCode;
        NSString *errorReason = [NSString stringWithFormat:@"errorReason = %@", [self getErrorFromCode:errorCode]];
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:isErrorCode userInfo:@{NSLocalizedDescriptionKey:errorReason}];
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void)interstitialDidPresentScreen:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
    }
}

- (void)interstitialDidDismissScreen:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

- (void)interstitialImpressionFired:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidShow];
    }
}

#pragma mark - Banner API

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingDataForAuctioneer:bannerAPSData andSaveMediationHints:bannerTimestampToMediationHints];
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);
    
    [_placementIdToBannerSmashDelegate setObject:delegate forKey:placementID];
    ISAPSBannerListener *bannerListener = [[ISAPSBannerListener alloc] initWithPlacementID:placementID andDelegate:self];
    [_placementIdToBannerAPSListener setObject:bannerListener forKey:placementID];
    // Publishers are expected to iniitalize the APS SDK. We therefore have no init method and should just return init success for the mediation to proceed as expected
    [delegate adapterBannerInitSuccess];
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *placementID = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);
    
    if (!serverData.length) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey:@"APS server data is empty"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    NSDictionary* mediationHints = nil;
    
    @synchronized (APSDataLock) {
        if (![bannerTimestampToMediationHints hasObjectForKey:serverData]) {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:@"APS server data is invalid"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
            return;
        }
        
        mediationHints = [bannerTimestampToMediationHints objectForKey:serverData];
        [bannerTimestampToMediationHints removeObjectForKey:serverData];
    }
    
    //create APS ad
    dispatch_async(dispatch_get_main_queue(), ^{
        ISAPSBannerListener *bannerDelegate = [self.placementIdToBannerAPSListener objectForKey:placementID];
        CGRect bannerSize = [self getBannerRectSize:size];
        DTBAdBannerDispatcher *dispatcher = [[DTBAdBannerDispatcher alloc] initWithAdFrame:bannerSize delegate:bannerDelegate];
        [self.placementIdToBannerAd setObject:dispatcher forKey:placementID];
        [dispatcher fetchBannerAdWithParameters: mediationHints];
    });
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementID = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementID = %@", placementID);

    DTBAdBannerDispatcher *banner = [_placementIdToBannerAd objectForKey:placementID];
    
    if (banner != nil) {
        // remove banner from the map
        [_placementIdToBannerAd removeObjectForKey:placementID];
        [_placementIdToBannerSmashDelegate removeObjectForKey:placementID];
        [_placementIdToBannerAPSListener removeObjectForKey:placementID];
    }
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES; // network does not support banner reload
}


#pragma mark - Banner Delegate
- (void)bannerAdDidLoad:(NSString *)placementId withBanner:(UIView *)adView {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerDidLoad:adView];
    }
}

- (void)bannerAdFailedToLoad:(NSString *)placementId errorCode:(NSInteger)errorCode {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        NSInteger isErrorCode = (errorCode == SampleErrorCodeNoInventory) ? ERROR_BN_LOAD_NO_FILL : errorCode;
        NSString *errorReason = [NSString stringWithFormat:@"errorReason = %@", [self getErrorFromCode:errorCode]];
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:isErrorCode userInfo:@{NSLocalizedDescriptionKey:errorReason}];
        [delegate adapterBannerDidFailToLoadWithError:smashError];
    }
}

- (void)bannerWillLeaveApplication:(NSString *)placementId {
    LogAdapterDelegate_Info(@"pacementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

- (void)bannerImpressionFired:(NSString *)placementId {
    LogAdapterDelegate_Info(@"pacementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterBannerDidShow];
        
    }
}

#pragma mark - Helper Methods

- (NSDictionary *)getBiddingDataForAuctioneer:(ConcurrentMutableDictionary *)apsData andSaveMediationHints:(ConcurrentMutableDictionary *)tokenToMediationHints {
    NSDictionary *data;
    
    if ([apsData count]) {
        @synchronized (APSDataLock) {
            NSString *uuid = [apsData objectForKey:kUUID];
            NSString *pricePointEncoded = [apsData objectForKey:kPricePointEncoded];
            NSString *token = [apsData objectForKey:kToken];
            NSDictionary *mediationHints = [apsData objectForKey:kMediationHints];
            bool hasSizes = [apsData hasObjectForKey:kWidth] && [apsData hasObjectForKey:kHeight];
            if (hasSizes) {
                NSNumber *width = [apsData objectForKey:kWidth];
                NSNumber *height = [apsData objectForKey:kHeight];
                data = @{kUUID:uuid, kPricePointEncoded:pricePointEncoded, kToken:token, kWidth:width, kHeight:height};
            } else {
                data = @{kUUID:uuid, kPricePointEncoded:pricePointEncoded, kToken:token};
            }
            [tokenToMediationHints removeAllObjects];
            [tokenToMediationHints setObject:mediationHints forKey:token];
            // We should use the data only once per auction attempt and therefore remove it
            [apsData removeAllObjects];
        }
    }
    
    if ([data count]) {
        LogAdapterApi_Internal(@"BiddingData = %@", data);
        return data;
    }
    
    return nil;
    
}

- (CGRect) getBannerRectSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return CGRectMake(0, 0, 320, 50);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CGRectMake(0, 0, 300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, 728, 90);
        }
        else {
            return CGRectMake(0, 0, 320, 50);
        }
    }
    return CGRectZero;
}

- (NSString *)getErrorFromCode:(DTBAdErrorCode)errorCode{
    switch (errorCode) {
        case SampleErrorCodeBadRequest:
            return @"Bad request";
        case SampleErrorCodeUnknown:
            return @"Unknown error";
        case SampleErrorCodeNetworkError:
            return @"Network error";
        case SampleErrorCodeNoInventory:
            return @"No Inventory";
        default:
            return [NSString stringWithFormat:@"unknonw error code: %d", (int) errorCode];
    }
}

@end
