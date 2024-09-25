#import "ISMobileFuseRewardedVideoAdapter.h"
#import "ISMobileFuseRewardedVideoDelegate.h"
#import "MobileFuseSDK/MobileFuse.h"

@interface ISMobileFuseRewardedVideoAdapter ()

@property (nonatomic, weak)   ISMobileFuseAdapter *adapter;
@property (nonatomic, strong) MFAd *ad;
@property (nonatomic, strong) ISMobileFuseRewardedVideoDelegate *mobileFuseAdDelegate;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> smashDelegate;

@end

@implementation ISMobileFuseRewardedVideoAdapter

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

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kPlacementId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
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
            [delegate adapterRewardedVideoInitSuccess];
            break;
            
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"MobileFuseSDK init failed"]];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // create rewarded ad delegate
    ISMobileFuseRewardedVideoDelegate *adDelegate = [[ISMobileFuseRewardedVideoDelegate alloc] initWithPlacementId:placementId
                                                                                                           andDelegate:delegate];
    self.mobileFuseAdDelegate = adDelegate;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = [[MFRewardedAd alloc] initWithPlacementId:placementId];
        [self.ad registerAdCallbackReceiver:self.mobileFuseAdDelegate];
        // load ad
        [self.ad loadAdWithBiddingResponseToken:serverData];
    });
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
        
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];

    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        // show ad
        [viewController.view addSubview:self.ad];
        [self.ad showAd];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && self.ad.isLoaded;
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    
    [self.adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterRewardedVideoInitSuccess];
}


- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    [self.smashDelegate adapterRewardedVideoInitFailed:error];
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
