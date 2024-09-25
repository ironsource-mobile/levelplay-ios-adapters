#import "ISMobileFuseBannerAdapter.h"
#import "ISMobileFuseBannerDelegate.h"
#import <MobileFuseSDK/MFBannerAd.h>

@interface ISMobileFuseBannerAdapter ()

@property (nonatomic, weak) ISMobileFuseAdapter *adapter;
@property (nonatomic, strong) MFAd *ad;
@property (nonatomic, strong) ISMobileFuseBannerDelegate *mobileFuseAdDelegate;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> smashDelegate;

@end

@implementation ISMobileFuseBannerAdapter

- (instancetype)initWithMobileFuseAdapter:(ISMobileFuseAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _ad = nil;
        _mobileFuseAdDelegate = nil;
    }
    return self;
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
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
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                withMessage:@"MobileFuseSDK init failed"]];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // get size
    MFBannerAdSize bannerSize = [self getBannerSize:size];
    
    // create banner ad delegate
    ISMobileFuseBannerDelegate *bannerAdDelegate = [[ISMobileFuseBannerDelegate alloc] initWithPlacementId:placementId
                                                                                       andDelegate:delegate];
    self.mobileFuseAdDelegate = bannerAdDelegate;
    
    if (bannerSize == MOBILEFUSE_BANNER_SIZE_DEFAULT) {
        NSError *error = [ISError createErrorWithDomain:kAdapterName
                                                   code:ERROR_BN_UNSUPPORTED_SIZE
                                                message:@"Unsupported banner size"];
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    // create banner view
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = [[MFBannerAd alloc] initWithPlacementId:placementId 
                                                 withSize:bannerSize];
        
        [self.ad registerAdCallbackReceiver:self.mobileFuseAdDelegate];
        [self.ad setMuted:YES]; // banner ads should be muted
        
        [self.ad loadAdWithBiddingResponseToken:serverData];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
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
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Helper Methods

- (MFBannerAdSize)getBannerSize:(ISBannerSize *)size {

   if ([size.sizeDescription isEqualToString:kSizeBanner]) {
       return MOBILEFUSE_BANNER_SIZE_320x50;
   } else if ([size.sizeDescription isEqualToString:kSizeRectangle]) {
       return MOBILEFUSE_BANNER_SIZE_300x250;
   } else if ([size.sizeDescription isEqualToString:kSizeLeaderboard]) {
       return MOBILEFUSE_BANNER_SIZE_728x90;
   }
    return MOBILEFUSE_BANNER_SIZE_DEFAULT;
}

@end

