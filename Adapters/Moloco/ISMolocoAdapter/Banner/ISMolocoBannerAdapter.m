//
//  ISMolocoBannerAdapter.m
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISMolocoBannerAdapter.h"
#import "ISMolocoBannerDelegate.h"

@interface ISMolocoBannerAdapter ()

@property (nonatomic, weak) ISMolocoAdapter *adapter;
@property (nonatomic, strong) MolocoBannerAdView *ad;
@property (nonatomic, strong) ISMolocoBannerDelegate *molocoAdDelegate;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> smashDelegate;

@end

@implementation ISMolocoBannerAdapter

- (instancetype)initWithMolocoAdapter:(ISMolocoAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _ad = nil;
        _molocoAdDelegate = nil;
    }
    return self;
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *appKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                      forKey:kAppKey];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    self.smashDelegate = delegate;
    
    LogAdapterApi_Internal(@"appKey = %@, adUnitId = %@", appKey, adUnitId);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppKey:appKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                withMessage:@"Moloco SDK init failed"]];
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
                                                        forKey:kAdUnitId];
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    // get size
    MolocoBannerType adSize = [self getBannerSize:size];
    
    // create banner ad delegate
    ISMolocoBannerDelegate *bannerAdDelegate = [[ISMolocoBannerDelegate alloc] initWithAdUnitId:adUnitId
                                                                                       andDelegate:delegate];
    self.molocoAdDelegate = bannerAdDelegate;
    
    // create banner view
    dispatch_async(dispatch_get_main_queue(), ^{
        MolocoBannerAdView *bannerAdView = [self createBannerWithAdSize:adSize
                                                               adUnitId:adUnitId
                                                         viewController:viewController
                                                               delegate:bannerAdDelegate];
    bannerAdView.delegate = bannerAdDelegate;

    // add banner ad to local variable
    self.ad = bannerAdView;
    
    // load ad
        [self.ad loadWithBidResponse:serverData];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    [self.ad destroy];
    self.ad.delegate = nil;
    self.ad = nil;
    self.smashDelegate = nil;
    self.molocoAdDelegate = nil;
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
                                                        forKey:kAdUnitId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Helper Methods

- (MolocoBannerType)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return MolocoBannerTypeRegular;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return MolocoBannerTypeMrec;
    }
    return MolocoBannerTypeRegular;
}

- (MolocoBannerAdView *)createBannerWithAdSize:(MolocoBannerType)adSize
                                       adUnitId:(NSString *)adUnitId
                                    viewController:(UIViewController *)viewController
                                          delegate:(id<MolocoBannerDelegate>)delegate {
    MolocoBannerAdView *bannerAdView = nil;
    
    if (adSize == MolocoBannerTypeMrec) {
        bannerAdView = [[Moloco shared] createMRECFor:adUnitId viewController:viewController delegate:delegate];
    } else if (adSize == MolocoBannerTypeRegular){
        bannerAdView = [[Moloco shared] createBannerFor:adUnitId viewController:viewController delegate:delegate watermarkData:nil];
    }
    return bannerAdView;
}

@end
