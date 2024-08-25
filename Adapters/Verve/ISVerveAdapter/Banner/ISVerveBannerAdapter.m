//
//  ISVerveBannerAdapter.m
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISVerveBannerAdapter.h"
#import "ISVerveBannerDelegate.h"

@interface ISVerveBannerAdapter ()

@property (nonatomic, weak) ISVerveAdapter *adapter;
@property (nonatomic, strong) HyBidAdView *ad;
@property (nonatomic, strong) ISVerveBannerDelegate *verveAdDelegate;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> smashDelegate;

@end

@implementation ISVerveBannerAdapter

- (instancetype)initWithVerveAdapter:(ISVerveAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _ad = nil;
        _verveAdDelegate = nil;
    }
    return self;
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *appToken = [self getStringValueFromAdapterConfig:adapterConfig
                                                      forKey:kAppToken];
        
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appToken]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppToken];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    self.smashDelegate = delegate;
    
    LogAdapterApi_Internal(@"appToken = %@, adUnitId = %@", appToken, adUnitId);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppToken:appToken];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - appToken = %@", appToken);
            [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                withMessage:@"Verve SDK init failed"]];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *zoneId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    // create banner ad delegate
    ISVerveBannerDelegate *bannerAdDelegate = [[ISVerveBannerDelegate alloc]
                                               initWithZoneId:zoneId
                                               andDelegate:delegate];
    self.verveAdDelegate = bannerAdDelegate;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = [[HyBidAdView alloc] initWithSize:[self getBannerSize:size]];
        [self.ad renderAdWithContent: serverData
                        withDelegate: self.verveAdDelegate];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.ad) {
            self.ad = nil;
        }
        if (self.ad && self.ad.delegate) {
            self.ad.delegate = nil;
        }
    });
    
    self.smashDelegate = nil;
    self.verveAdDelegate = nil;
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
    NSString *zoneId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Helper Methods

- (HyBidAdSize *)getBannerSize:(ISBannerSize *)ironSourceAdSize {
    if ([ironSourceAdSize.sizeDescription isEqualToString:kSizeRectangle]) {
        return HyBidAdSize.SIZE_300x250;
    } else if ([ironSourceAdSize.sizeDescription isEqualToString:kSizeSmart]) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad){
            return HyBidAdSize.SIZE_728x90;
        } else {
            return HyBidAdSize.SIZE_320x50;
        }
    } else {
        return HyBidAdSize.SIZE_320x50;
    }
}

@end
