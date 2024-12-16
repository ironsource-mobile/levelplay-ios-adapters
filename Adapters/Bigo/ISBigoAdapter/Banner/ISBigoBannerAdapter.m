#import "ISBigoBannerAdapter.h"
#import "ISBigoBannerDelegate.h"

@interface ISBigoBannerAdapter ()

@property (nonatomic, weak) ISBigoAdapter *adapter;
@property (nonatomic, strong) BigoBannerAd *ad;
@property (nonatomic, strong) BigoBannerAdLoader *adLoader;
@property (nonatomic, strong) ISBigoBannerDelegate *bigoAdDelegate;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> smashDelegate;

@end

@implementation ISBigoBannerAdapter

- (instancetype)initWithBigoAdapter:(ISBigoAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _ad = nil;
        _bigoAdDelegate = nil;
    }
    return self;
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *appId = [self getStringValueFromAdapterConfig:adapterConfig
                                                      forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:slotId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    self.smashDelegate = delegate;
    
    LogAdapterApi_Internal(@"appKey = %@, slotId = %@", appId, slotId);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppKey:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                withMessage:@"Bigo SDK init failed"]];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    // get size
    
    // create banner ad delegate
    ISBigoBannerDelegate *bannerAdDelegate = [[ISBigoBannerDelegate alloc] initWithSlotId:slotId
                                                                         andBannerAdapter:self
                                                                              andDelegate:delegate];
    self.bigoAdDelegate = bannerAdDelegate;
    
    // create banner view
    dispatch_async(dispatch_get_main_queue(), ^{
        BigoBannerAdRequest *request = [[BigoBannerAdRequest alloc] initWithSlotId:slotId
                                                                           adSizes:@[BigoAdSize.BANNER]];
        
        [request setServerBidPayload:serverData];
        
        ISBigoAdapter *bigoAdapter = [[ISBigoAdapter alloc] init];
        NSString *mediationInfo = [bigoAdapter getMediationInfo];
        
        self.adLoader = [[BigoBannerAdLoader alloc] initWithBannerAdLoaderDelegate:bannerAdDelegate];
        self.adLoader.ext = mediationInfo;
        [self.adLoader loadAd:request];
    });
}

- (void)setBannerAd:(BigoBannerAd *)ad {
    self.ad = ad;
    [ad setAdInteractionDelegate:self.bigoAdDelegate];
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad destroy];
        self.ad = nil;
    });
    self.smashDelegate = nil;
    self.bigoAdDelegate = nil;
}

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           adData:(NSDictionary *)adData
                                         delegate:(id<ISBiddingDataDelegate>)delegate {
    
    [self.adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterBannerInitSuccess];
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    [self.smashDelegate adapterBannerInitFailedWithError:error];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Helper Methods

- (BigoAdSize *)getBannerSize:(ISBannerSize *)size {
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return BigoAdSize.BANNER;
    }
    if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return BigoAdSize.MEDIUM_RECTANGLE;
    }
    if([size.sizeDescription isEqualToString:@"SMART"]){
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return BigoAdSize.LARGE_BANNER;
        } else {
            return BigoAdSize.BANNER;
        }
    }
    
    return nil;
}

@end
