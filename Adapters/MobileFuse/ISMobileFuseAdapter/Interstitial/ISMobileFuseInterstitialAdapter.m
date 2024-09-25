#import "ISMobileFuseInterstitialAdapter.h"
#import "ISMobileFuseInterstitialDelegate.h"
#import <MobileFuseSDK/MFInterstitialAd.h>

@interface ISMobileFuseInterstitialAdapter ()

@property (nonatomic, weak)   ISMobileFuseAdapter *adapter;
@property (nonatomic, strong) MFInterstitialAd *ad;
@property (nonatomic, strong) ISMobileFuseInterstitialDelegate *mobileFuseAdDelegate;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> smashDelegate;

@end

@implementation ISMobileFuseInterstitialAdapter

- (instancetype)initWithMobileFuseAdapter:(ISMobileFuseAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _mobileFuseAdDelegate = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithPlacementId:kPlacementId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                      withMessage:@"MobileFuseSDK init failed"]];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // create interstitial ad delegate
    ISMobileFuseInterstitialDelegate *adDelegate = [[ISMobileFuseInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                                     andDelegate:delegate];
    self.mobileFuseAdDelegate = adDelegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = [[MFInterstitialAd alloc] initWithPlacementId:placementId];
        [self.ad registerAdCallbackReceiver:adDelegate];
        // load ad
        [self.ad loadAdWithBiddingResponseToken:serverData];
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // show ad
        [viewController.view addSubview:self.ad];
        [self.ad showAd];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && self.ad.isLoaded;
    
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

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    [self.smashDelegate adapterInterstitialInitFailedWithError:error];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad destroy];
        self.ad = nil;
    });
    self.smashDelegate = nil;
    self.mobileFuseAdDelegate = nil;
}

@end
