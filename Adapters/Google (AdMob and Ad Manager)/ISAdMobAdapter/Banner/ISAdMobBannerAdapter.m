//
//  ISAdMobBannerAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import "ISAdMobBannerAdapter.h"
#import "ISAdMobBannerDelegate.h"
#import "ISAdMobNativeBannerDelegate.h"

@interface ISAdMobBannerAdapter ()

@property (nonatomic, weak) ISAdMobAdapter *adapter;

// Banner & Native banner
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAds;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAdDelegate;

// You must keep a strong reference to the GADAdLoader during the ad loading process.
@property (nonatomic, strong) GADAdLoader *nativeAdLoader;

@end

@implementation ISAdMobBannerAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                     = adapter;
        _adUnitIdToAds               = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToSmashDelegate     = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToAdDelegate        = [ISConcurrentMutableDictionary dictionary];
    }
    return self;
}

- (void)initBannerWithUserId:(NSString *)userId
               adapterConfig:(ISAdapterConfig *)adapterConfig
                    delegate:(id<ISBannerAdapterDelegate>)delegate {
    [self initBannersInternalWithAdapterConfig:adapterConfig
                                      delegate:delegate];
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    [self initBannersInternalWithAdapterConfig:adapterConfig
                                      delegate:delegate];
}

- (void)initBannersInternalWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
        
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    [self.adUnitIdToSmashDelegate setObject:delegate
                                     forKey:adUnitId];
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initAdMobSDKWithAdapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                withMessage:@"AdMob SDK init failed"]];
            break;
        }
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
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    [self loadBannerInternalWithViewController:viewController
                                          size:size
                                 adapterConfig:adapterConfig
                                        adData:adData
                                    serverData:serverData
                                      delegate:delegate];
}

- (void)loadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             adData:(NSDictionary *)adData
                     viewController:(UIViewController *)viewController
                               size:(ISBannerSize *)size
                           delegate:(id <ISBannerAdapterDelegate>)delegate {
    [self loadBannerInternalWithViewController:viewController
                                          size:size
                                 adapterConfig:adapterConfig
                                        adData:adData
                                    serverData:nil
                                      delegate:delegate];
}

- (void)loadBannerInternalWithViewController:(UIViewController *)viewController
                                        size:(ISBannerSize *)size
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                      adData:(NSDictionary *)adData
                                  serverData:(NSString *)serverData
                                    delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    //add to banner delegate dictionary
    [self.adUnitIdToSmashDelegate setObject:delegate
                                     forKey:adUnitId];

    
    dispatch_async(dispatch_get_main_queue(), ^{

        BOOL isNative = [adapterConfig.settings[kIsNative] boolValue];
        
        GADRequest *request = [self.adapter createGADRequestForLoadWithAdData:adData
                                                                   serverData:serverData];
        
        if (isNative) {
            [self loadNativeBannerWithViewController:viewController
                                       adapterConfig:adapterConfig
                                             request:request
                                                size:size
                                            delegate:delegate];
            return;
        }
        
        // validate banner size
        if([self isBannerSizeSupported:size]){
            
            // get size
            GADAdSize adMobSize = [self getBannerSize:size];
            
            // create banner
            GADBannerView *banner = [[GADBannerView alloc] initWithAdSize:adMobSize];
            ISAdMobBannerDelegate *bannerDelegate = [[ISAdMobBannerDelegate alloc] initWithAdUnitId:adUnitId
                                                                                        andDelegate:delegate];
            //add banner to delegate map
            [self.adUnitIdToAdDelegate setObject:bannerDelegate
                                          forKey:adUnitId];
            
            banner.delegate = bannerDelegate;
            banner.adUnitID = adUnitId;
            banner.rootViewController = viewController;
            
            // add to dictionary
            [self.adUnitIdToAds setObject:banner
                                   forKey:adUnitId];
            
            // load request
            [banner loadRequest:request];
            
        }else{
            // size not supported
            NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE
                                      withMessage:@"AdMob unsupported banner size"];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
        
    });
}

- (void)loadNativeBannerWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                   request:(GADRequest *)request
                                      size:(ISBannerSize *)size
                                  delegate:(id<ISBannerAdapterDelegate>)delegate{
    
    // validate native banner size
    if([self isNativeBannerSizeSupported:size]) {
        
        NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                            forKey:kAdUnitId];
        
        ISAdMobNativeBannerTemplate *template = [[ISAdMobNativeBannerTemplate alloc] initWithAdapterConfig:adapterConfig
                                                                                           sizeDescription:size.sizeDescription];
        self.nativeAdLoader = [[GADAdLoader alloc] initWithAdUnitID: adUnitId
                                                 rootViewController: viewController
                                                            adTypes: @[GADAdLoaderAdTypeNative]
                                                            options: [self createNativeAdOptionsWithTemplate:template]];
        
        ISAdMobNativeBannerDelegate* nativeBannerDelegate = [[ISAdMobNativeBannerDelegate alloc] initWithAdUnitId:adUnitId
                                                                                                   nativeTemplate:template
                                                                                                         delegate:delegate];

        //add native banner to delegate map
        [self.adUnitIdToAdDelegate setObject:nativeBannerDelegate
                                      forKey:adUnitId];
        
        self.nativeAdLoader.delegate = nativeBannerDelegate;
        [self.nativeAdLoader loadRequest:request];
    } else {
        // size not supported
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE
                                  withMessage:@"AdMob unsupported banner size"];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (NSArray<GADAdLoaderOptions *> *)createNativeAdOptionsWithTemplate:(ISAdMobNativeBannerTemplate *)template {
    GADVideoOptions *videoOptions = [[GADVideoOptions alloc] init];
    videoOptions.startMuted = true;
    
    GADNativeAdViewAdOptions *adViewAdOptions = [[GADNativeAdViewAdOptions alloc] init];
    adViewAdOptions.preferredAdChoicesPosition = template.adChoicesPosition;

    GADNativeAdMediaAdLoaderOptions *adMediaAdLoaderOptions = [[GADNativeAdMediaAdLoaderOptions alloc] init];
    adMediaAdLoaderOptions.mediaAspectRatio = template.mediaAspectRatio;

    return @[videoOptions, adViewAdOptions, adMediaAdLoaderOptions];
}


- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

// destroy banner ad
- (void) destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    self.nativeAdLoader = nil;
    
    // remove from dictionary
    [self.adUnitIdToAdDelegate removeObjectForKey:adUnitId];
    [self.adUnitIdToSmashDelegate removeObjectForKey:adUnitId];
}


- (CGFloat)getAdaptiveHeightWithWidth:(CGFloat)width {
    
    CGFloat height = [self getAdmobAdaptiveAdSizeWithWidth:width].size.height;
    LogAdapterApi_Internal(@"%@", [NSString stringWithFormat:@"height - %.2f for width - %.2f", height, width]);
    
    return height;
}

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           adData:(NSDictionary *)adData
                                         delegate:(id<ISBiddingDataDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        GADRequest *request = [GADRequest request];
        request.requestAgent = kRequestAgent;
        NSMutableDictionary *additionalParameters = [[NSMutableDictionary alloc] init];
        additionalParameters[kAdMobQueryInfoType] = kAdMobRequesterType;
        
        if (adData) {
            if ([adData objectForKey:@"bannerSize"]) {
                ISBannerSize *size = [adData objectForKey:@"bannerSize"];
                
                if (size.adaptive) {
                    GADAdSize adSize = [self getBannerSize:size];
                    additionalParameters[kAdMobAdaptiveBannerWidth] = @(adSize.size.width);
                    additionalParameters[kAdMobAdaptiveBannerHeight] = @(adSize.size.height);
                    LogInternal_Internal(@"adaptive banner width = %@, height = %@", @(adSize.size.width), @(adSize.size.height));
                }
            }
        }
        GADExtras *extras = [[GADExtras alloc] init];
        extras.additionalParameters = additionalParameters;
        [request registerAdNetworkExtras:extras];
        
        [self.adapter collectBiddingDataWithAdData:request
                                          adFormat:GADAdFormatBanner
                                          delegate:delegate];
    });
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    NSArray *bannerAdUnitIds = self.adUnitIdToSmashDelegate.allKeys;
    
    for (NSString *adUnitId in bannerAdUnitIds) {
        id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    NSArray *bannerAdUnitIds = self.adUnitIdToSmashDelegate.allKeys;
    
    for (NSString *adUnitId in bannerAdUnitIds) {
        id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    self.nativeAdLoader = nil;
    
    // remove from dictionaries
    if ([self.adUnitIdToAdDelegate hasObjectForKey:adUnitId]) {
        [self.adUnitIdToAdDelegate removeObjectForKey:adUnitId];
    }
    if ([self.adUnitIdToSmashDelegate hasObjectForKey:adUnitId]) {
        [self.adUnitIdToSmashDelegate removeObjectForKey:adUnitId];
    }
}

#pragma mark - Helper Methods

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]      ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]  ||
        [size.sizeDescription isEqualToString:@"SMART"]      ||
        [size.sizeDescription isEqualToString:@"CUSTOM"]
        ) {
        return YES;
    }
    
    return NO;
}

- (bool)isNativeBannerSizeSupported:(ISBannerSize *)size {
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]      ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]
        ) {
        return YES;
    }
    
    //in this case banner size is returned
    if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return ![self isLargeScreen];
    }
    
    return NO;
}

- (GADAdSize)getBannerSize:(ISBannerSize *)size {
    GADAdSize adMobSize = GADAdSizeInvalid;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        adMobSize = GADAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        adMobSize = GADAdSizeLargeBanner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        adMobSize = GADAdSizeMediumRectangle;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if ([self isLargeScreen]) {
            adMobSize = GADAdSizeLeaderboard;
        } else {
            adMobSize = GADAdSizeBanner;
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        adMobSize = GADAdSizeFromCGSize(CGSizeMake(size.width, size.height));
    }
    
    if ([size respondsToSelector:@selector(containerParams)]) {
        if (size.isAdaptive) {
            adMobSize = [self getAdmobAdaptiveAdSizeWithWidth:size.containerParams.width];
            LogAdapterApi_Internal(@"default height - %@ adaptive height - %@ container height - %@ default width - %@ container width - %@", @(size.height), @(adMobSize.size.height), @(size.containerParams.height), @(size.width), @(size.containerParams.width));
        }
    } else {
        LogInternal_Error(@"containerParams is not supported");
    }
    
    return adMobSize;
}

- (GADAdSize) getAdmobAdaptiveAdSizeWithWidth:(CGFloat) width {
    __block GADAdSize adaptiveSize;
    
    void (^calculateAdaptiveSize)(void) = ^{
        adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width);
    };
    
    if([NSThread isMainThread]) {
        calculateAdaptiveSize();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            calculateAdaptiveSize();
        });
    }
    
    return adaptiveSize;
}

- (BOOL) isLargeScreen {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

@end

