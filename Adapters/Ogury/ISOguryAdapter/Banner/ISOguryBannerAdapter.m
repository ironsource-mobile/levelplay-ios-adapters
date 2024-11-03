#import "ISOguryBannerAdapter.h"
#import "ISOguryBannerDelegate.h"

@interface ISOguryBannerAdapter ()

@property (nonatomic, weak) ISOguryAdapter *adapter;
@property (nonatomic, strong) OguryBannerAd *ad;
@property (nonatomic, strong) ISOguryBannerDelegate *oguryAdDelegate;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> smashDelegate;

@end

@implementation ISOguryBannerAdapter

- (instancetype)initWithOguryAdapter:(ISOguryAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _ad = nil;
        _oguryAdDelegate = nil;
    }
    return self;
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *assetKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                      forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:assetKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
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
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                withMessage:@"OgurySDK init failed"]];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    OguryAdsBannerSize * bannerSize = [self getBannerSize:size];
    
    // create banner ad delegate
    ISOguryBannerDelegate *bannerAdDelegate = [[ISOguryBannerDelegate alloc] initWithAdUnitId:adUnitId
                                                                                  andDelegate:delegate];
    self.oguryAdDelegate = bannerAdDelegate;
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (bannerSize == nil) {
            NSError *error = [ISError createErrorWithDomain:kAdapterName
                                                       code:ERROR_BN_UNSUPPORTED_SIZE
                                                    message:@"Unsupported banner size"];
            [delegate adapterBannerDidFailToLoadWithError:error];
            return;
        }
        
        self.ad = [[OguryBannerAd alloc] initWithAdUnitId:adUnitId];
        self.ad.delegate = self.oguryAdDelegate;
        
        CGRect bannerFrame = [self getBannerFrame:size];
        self.ad.frame = bannerFrame;

        [self.ad loadWithAdMarkup:serverData
                             size:bannerSize];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.ad) {
            [self.ad destroy];
            self.ad = nil;
        };
    });
    
    self.smashDelegate = nil;
    self.oguryAdDelegate = nil;
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
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Helper Methods

- (OguryAdsBannerSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:kSizeBanner]) {
        return OguryAdsBannerSize.small_banner_320x50;
    } else if ([size.sizeDescription isEqualToString:kSizeRectangle]) {
        return OguryAdsBannerSize.mpu_300x250;
    }
    return nil;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    CGRect rect = CGRectZero;

    NSInteger height = size.height;
    NSInteger width = size.width;
    
    return CGRectMake(0, 0, width, height);
}

@end