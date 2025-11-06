//
//  ISPubMaticBannerAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticBannerAdapter.h"
#import "ISPubMaticBannerDelegate.h"

@interface ISPubMaticBannerAdapter ()

@property (nonatomic, weak)   ISPubMaticAdapter             *adapter;
@property (nonatomic, strong) POBBannerView                 *ad;
@property (nonatomic, strong) ISPubMaticBannerDelegate      *adDelegate;
@property (nonatomic, weak)   id<ISBannerAdapterDelegate>   smashDelegate;

@end

@implementation ISPubMaticBannerAdapter

- (instancetype)initWithPubMaticAdapter:(ISPubMaticAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _ad = nil;
        _adDelegate = nil;
    }
    return self;
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    /* Configuration Validations */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *publisherId = [self getStringValueFromAdapterConfig:adapterConfig
                                                          forKey:kPublisherId];
    
    if (![self.adapter isConfigValueValid:publisherId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPublisherId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *profileId = [self getStringValueFromAdapterConfig:adapterConfig
                                                         forKey:kProfileId];
    
    if (![self.adapter isConfigValueValid:profileId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kProfileId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    self.smashDelegate = delegate;
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithConfig:adapterConfig];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                withMessage:@"PubMatic SDK init failed"]];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig forKey:kAdUnitId];

    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    dispatch_async(dispatch_get_main_queue(), ^{
        // create banner ad delegate
        ISPubMaticBannerDelegate *adDelegate = [[ISPubMaticBannerDelegate alloc] initWithAdUnitId:adUnitId
                                                                                          adapter:self.adapter
                                                                                         andDelegate:delegate];
        self.adDelegate = adDelegate;
        self.ad = [[POBBannerView alloc] init];
        self.ad.delegate = self.adDelegate;
        // load ad
        [self.ad loadAdWithResponse:serverData forBiddingHost:POBSDKBiddingHostUnityLevelPlay];
        [self.ad pauseAutoRefresh];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    self.ad.delegate = nil;
    self.ad = nil;
    self.smashDelegate = nil;
    self.adDelegate = nil;
}

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           adData:(NSDictionary *)adData
                                         delegate:(id<ISBiddingDataDelegate>)delegate {
    if ([adData objectForKey:@"bannerSize"]) {
        ISBannerSize *size = [adData objectForKey:@"bannerSize"];
        POBAdFormat bannerFormat = [self getBannerFormat:size];
        
        [self.adapter collectBiddingDataWithDelegate:delegate
                                            adFormat:bannerFormat
                                       adapterConfig:adapterConfig];
    }
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

#pragma mark - Helper Methods

- (POBAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:kSizeBanner]) {
        return POBBannerAdSize320x50;
    } else if ([size.sizeDescription isEqualToString:kSizeLarge]) {
        return POBBannerAdSize320x100;
    } else if ([size.sizeDescription isEqualToString:kSizeRectangle]) {
        return POBBannerAdSize300x250;
    } else if ([size.sizeDescription isEqualToString:kSizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return POBBannerAdSize728x90;
        } else {
            return POBBannerAdSize320x50;
        }
    }
    return nil;
}

- (POBAdFormat)getBannerFormat:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:kSizeRectangle]) {
        return POBAdFormatMREC;
    }
    return POBAdFormatBanner;
}

@end
