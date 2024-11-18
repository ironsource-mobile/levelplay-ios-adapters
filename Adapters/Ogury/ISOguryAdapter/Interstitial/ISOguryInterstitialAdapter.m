#import "ISOguryInterstitialAdapter.h"
#import "ISOguryInterstitialDelegate.h"
#import "ISOguryAdapter+Internal.h"
#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>

@interface ISOguryInterstitialAdapter ()

@property (nonatomic, weak)   ISOguryAdapter *adapter;
@property (nonatomic, strong) OguryInterstitialAd *ad;
@property (nonatomic, strong) ISOguryInterstitialDelegate *oguryAdDelegate;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> smashDelegate;

@end

@implementation ISOguryInterstitialAdapter

- (instancetype)initWithOguryAdapter:(ISOguryAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _oguryAdDelegate = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *assetKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:assetKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"assetKey = %@, adUnitId = %@", assetKey, adUnitId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAssetKey:assetKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                      withMessage:@"OgurySDK init failed"]];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];

    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    ISOguryInterstitialDelegate *adDelegate = [[ISOguryInterstitialDelegate alloc] initWithAdUnitId:adUnitId
                                                                                        andDelegate:delegate];
    
    self.oguryAdDelegate = adDelegate;
    self.ad = [[OguryInterstitialAd alloc] initWithAdUnitId:adUnitId
                                                  mediation:[[OguryMediation alloc] initWithName: kMediationName version:[IronSource sdkVersion]]];
    self.ad.delegate = self.oguryAdDelegate;

    [self.ad loadWithAdMarkup: serverData];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    if (![self.ad isLoaded]) {
        
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    [self.ad showAdInViewController: viewController];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self.ad isLoaded];
}


- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    [self.adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterInterstitialInitSuccess];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    if (self.ad) {
        self.ad.delegate = nil;
        self.ad = nil;
    };
    self.smashDelegate = nil;
    self.oguryAdDelegate = nil;
}

@end
