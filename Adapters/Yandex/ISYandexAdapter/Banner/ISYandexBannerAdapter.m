//
//  ISYandexBannerAdapter.m
//  ISYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexBannerAdapter.h"
#import "ISYandexBannerAdDelegate.h"

@interface ISYandexBannerAdapter ()

@property (nonatomic, weak)   ISYandexAdapter *adapter;
@property (nonatomic, strong) YMAAdView *ad;
@property (nonatomic, strong) ISYandexBannerAdDelegate *yandexAdDelegate;
@property (nonatomic, weak)   id<ISBannerAdapterDelegate> smashDelegate;

@end

@implementation ISYandexBannerAdapter

- (instancetype)initWithYandexAdapter:(ISYandexAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _ad = nil;
        _yandexAdDelegate = nil;
    }
    return self;
}

#pragma mark - Banner API's


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
    
    LogAdapterApi_Internal(@"appId = %@, adUnitId = %@", appId, adUnitId);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
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
    YMABannerAdSize *adSize = [self getBannerSize:size];

    // create banner ad delegate
    ISYandexBannerAdDelegate *adDelegate = [[ISYandexBannerAdDelegate alloc] initWithAdUnitId:adUnitId
                                                                                  andDelegate:delegate];
    self.yandexAdDelegate = adDelegate;

    dispatch_async(dispatch_get_main_queue(), ^{
        // create banner view
        YMAAdView *adView = [[YMAAdView alloc] initWithAdUnitID: adUnitId
                                                         adSize: adSize];
        adView.delegate = adDelegate;
        
        // add banner ad to local variable
        self.ad = adView;
        
        // get ad request parameters
        YMAMutableAdRequest *adRequest = [self.adapter createAdRequestWithBidResponse:serverData];
    
        // load ad
        [self.ad loadAdWithRequest:adRequest];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad.delegate = nil;
        self.ad = nil;
        self.smashDelegate = nil;
        self.yandexAdDelegate = nil;
    });
}

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig 
                                           adData:(NSDictionary *)adData
                                         delegate:(id<ISBiddingDataDelegate>)delegate {
    
    YMABidderTokenRequestConfiguration *requestConfiguration = [[YMABidderTokenRequestConfiguration alloc] initWithAdType:YMAAdTypeBanner];
    
    if (adData) {
        if ([adData objectForKey:@"bannerSize"]) {
            ISBannerSize *size = [adData objectForKey:@"bannerSize"];
            YMABannerAdSize *adSize = [self getBannerSize:size];
            [requestConfiguration setBannerAdSize:adSize];
        }
    }
    
    requestConfiguration.parameters = [self.adapter getConfigParams];

    [self.adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                    delegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterBannerInitSuccess];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Helper Methods

- (YMABannerAdSize *)getBannerSize:(ISBannerSize *)size {
    YMABannerAdSize *adSize = nil;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:320 height:50];
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:320 height:90];
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:300 height:250];
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            adSize = [YMABannerAdSize fixedSizeWithWidth:728 height:90];
        } else {
            adSize = [YMABannerAdSize fixedSizeWithWidth:320 height:50];
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        adSize = [YMABannerAdSize fixedSizeWithWidth:size.width height:size.height];
    }
    
    return adSize;
}

@end
