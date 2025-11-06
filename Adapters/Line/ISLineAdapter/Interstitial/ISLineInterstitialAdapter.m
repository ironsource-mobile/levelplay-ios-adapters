//
//  ISLineInterstitialAdapter.m
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISLineInterstitialAdapter.h"
#import "ISLineInterstitialDelegate.h"

@interface ISLineInterstitialAdapter ()

@property (nonatomic, weak)   ISLineAdapter                   *adapter;
@property (nonatomic, strong) FADInterstitial                 *ad;
@property (nonatomic, strong) FADAdLoader                     *adLoader;
@property (nonatomic, strong) ISLineInterstitialDelegate      *lineAdDelegate;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> smashDelegate;

@end

@implementation ISLineInterstitialAdapter

- (instancetype)initWithLineAdapter:(ISLineAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _adLoader = nil;
        _smashDelegate = nil;
        _lineAdDelegate = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appId = [self getAppId:adapterConfig];
    
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    NSString *slotId = [self getSlotId:adapterConfig];
    
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:slotId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"appId = %@, slotId = %@", appId, slotId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
            [self.adapter initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                      withMessage:@"LineSDK init failed"]];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appId = [self getAppId:adapterConfig];
    NSString *slotId = [self getSlotId:adapterConfig];

    LogAdapterApi_Internal(@"appId = %@, slotId = %@", appId, slotId);

    // create interstitial ad delegate
    ISLineInterstitialDelegate *adDelegate = [[ISLineInterstitialDelegate alloc] initWithSlotId:slotId
                                                                                        adapter:self
                                                                                        andDelegate:delegate];
    self.lineAdDelegate = adDelegate;
    self.adLoader = [self.adapter getAdLoader:appId];
    if (self.adLoader == nil){
        NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                  withMessage:[NSString stringWithFormat:@"%@ - adLoader is nil", kAdapterName]];
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    FADBidData *bidData = [[FADBidData alloc] initWithBidResponse: serverData withWatermark: nil];
    void (^interstitialLoadCallback)(FADInterstitial *_Nullable, NSError *_Nullable) = ^(FADInterstitial *_Nullable ad, NSError *_Nullable error) {
        if (error)
        {
            [delegate adapterInterstitialDidFailToLoadWithError:error];
            return;
        }
        
        if (!ad)
        {
            NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                      withMessage:[NSString stringWithFormat:@"%@ no ad", kAdapterName]];
            [delegate adapterInterstitialDidFailToLoadWithError:error];
            return;
        }
        self.ad = ad;
        [delegate adapterInterstitialDidLoad];
    };
    [self.adLoader loadInterstitialAdWithBidData:bidData
                                withLoadCallback:interstitialLoadCallback];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *slotId = [self getSlotId:adapterConfig];
    
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    if (self.ad) {
        [self.ad setEventListener: self.lineAdDelegate];
        [self.ad showWithViewController:viewController];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:@"No ad loaded yet"];
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil;
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *appId = [self getAppId:adapterConfig];
    NSString *slotId = [self getSlotId:adapterConfig];
    [self.adapter collectBiddingDataWithDelegate:delegate
                                           appId:appId
                                          slotId:slotId];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterInterstitialInitSuccess];
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    [self.smashDelegate adapterInterstitialInitFailedWithError:error];
}

#pragma mark - Memory Handling

- (void)destroyInterstitialAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotId = [self getSlotId:adapterConfig];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    self.ad = nil;
    [self.ad setEventListener:nil];
    self.smashDelegate = nil;
    self.lineAdDelegate.delegate = nil;
    self.lineAdDelegate = nil;
    self.adLoader = nil;
}

#pragma mark - Helper Methods

- (NSString *)getSlotId:(ISAdapterConfig *)adapterConfig {
    return [self getStringValueFromAdapterConfig:adapterConfig
                                          forKey:kSlotId];
}

- (NSString *)getAppId:(ISAdapterConfig *)adapterConfig {
    return [self getStringValueFromAdapterConfig:adapterConfig
                                          forKey:kAppId];
}

@end
