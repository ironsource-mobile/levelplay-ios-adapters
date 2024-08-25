//
//  ISFacebookBannerAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import "ISFacebookBannerAdapter.h"
#import "ISFacebookBannerDelegate.h"

@interface ISFacebookBannerAdapter ()

@property (nonatomic, weak) ISFacebookAdapter       *adapter;

@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToAd;

@end

@implementation ISFacebookBannerAdapter

- (instancetype)initWithFacebookAdapter:(ISFacebookAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                                        = adapter;
        _adUnitPlacementIdToSmashDelegate               = [ISConcurrentMutableDictionary dictionary];
        _adUnitPlacementIdToAdDelegate                  = [ISConcurrentMutableDictionary dictionary];
        _adUnitPlacementIdToAd                          = [ISConcurrentMutableDictionary dictionary];
        
    }
    return self;
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    [self initBannerWithUserId:userId
                 adapterConfig:adapterConfig
                      delegate:delegate];
}

- (void)initBannerWithUserId:(NSString *)userId
               adapterConfig:(ISAdapterConfig *)adapterConfig
                    delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    NSString *allPlacementIds = [self getStringValueFromAdapterConfig:adapterConfig
                                                               forKey:kAllPlacementIds];
    
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self.adapter isConfigValueValid:allPlacementIds]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    //add to banner delegate map
    [self.adUnitPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithPlacementIds:allPlacementIds];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Meta SDK init failed"}];
            [delegate adapterBannerInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    [self loadBannerInternal:serverData
              viewController:viewController
                        size:size
               adapterConfig:adapterConfig
                    delegate:delegate];
}

- (void)loadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             adData:(NSDictionary *)adData
                     viewController:(UIViewController *)viewController
                               size:(ISBannerSize *)size
                           delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    [self loadBannerInternal:nil
              viewController:viewController
                        size:size
               adapterConfig:adapterConfig
                    delegate:delegate];
}

- (void)loadBannerInternal:(NSString *)serverData
            viewController:(UIViewController *)viewController
                      size:(ISBannerSize *)size
             adapterConfig:(ISAdapterConfig *)adapterConfig
                  delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];

    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    //add to banner delegate map
    [self.adUnitPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        @try {
            
            // get size
            FBAdSize fbSize = [self getBannerSize:size];
            
            // get banner frame
            CGRect bannerFrame = [self getBannerFrame:size];
            
            if (CGRectEqualToRect(bannerFrame, CGRectZero)) {
                NSError *error = [NSError errorWithDomain:kAdapterName
                                                     code:ERROR_BN_UNSUPPORTED_SIZE
                                                 userInfo:@{NSLocalizedDescriptionKey:@"Meta unsupported banner size"}];
                [delegate adapterBannerDidFailToLoadWithError:error];
                return;
            }
            
            ISFacebookBannerDelegate *bannerAdDelegate = [[ISFacebookBannerDelegate alloc] initWithPlacementId:placementId
                                                                                                   andDelegate:delegate];
            [self.adUnitPlacementIdToAdDelegate setObject:bannerAdDelegate
                                                   forKey:placementId];
            
            // create banner view
            FBAdView *ad = [[FBAdView alloc] initWithPlacementID:placementId
                                                                adSize:fbSize
                                                    rootViewController:viewController];
            ad.frame = bannerFrame;
            
            // Set a delegate
            ad.delegate = bannerAdDelegate;
            
            // add banner ad to dictionary
            [self.adUnitPlacementIdToAd setObject:ad
                                           forKey:placementId];
            
            // load the ad
            if (serverData == nil) {
                [ad loadAd];
            } else {
                [ad loadAdWithBidPayload:serverData];
            }
            
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:exception.description}];
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // there is no required implementation for Meta destroy banner
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData {
    LogAdapterApi_Internal(@"");
    return [self.adapter getBiddingData];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    NSArray *placementIds = self.adUnitPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in placementIds) {
        id<ISBannerAdapterDelegate> delegate = [self.adUnitPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    NSArray *placementIds = self.adUnitPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in placementIds) {
        id<ISBannerAdapterDelegate> delegate = [self.adUnitPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // there is no required implementation for AdMob release memory

}

#pragma mark - Helper Methods

- (FBAdSize)getBannerSize:(ISBannerSize *)size {
    // Initing the banner size so it will have a default value. Since FBAdSize doesn't support CGSizeZero we used the default banner size isntead
    FBAdSize fbSize = kFBAdSizeHeight50Banner;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        fbSize = kFBAdSizeHeight50Banner;
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        fbSize = kFBAdSizeHeight90Banner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        fbSize = kFBAdSizeHeight250Rectangle;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            fbSize = kFBAdSizeHeight90Banner;
        } else {
            fbSize = kFBAdSizeHeight50Banner;
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        if (size.height == 50) {
            fbSize = kFBAdSizeHeight50Banner;
        } else if (size.height == 90) {
            fbSize = kFBAdSizeHeight90Banner;
        } else if (size.height == 250) {
            fbSize = kFBAdSizeHeight250Rectangle;
        }
    }
    
    return fbSize;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    CGRect rect = CGRectZero;

    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        rect = CGRectMake(0, 0, 320, 50);
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        rect = CGRectMake(0, 0, 320, 90);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        rect = CGRectMake(0, 0, 300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            rect = CGRectMake(0, 0, 728, 90);
        } else {
            rect = CGRectMake(0, 0, 320, 50);
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        if (size.height == 50) {
            rect = CGRectMake(0, 0, 320, 50);
        } else if (size.height == 90) {
            rect = CGRectMake(0, 0, 320, 90);
        } else if (size.height == 250) {
            rect = CGRectMake(0, 0, 300, 250);
        }
    }
    
    return rect;
}

@end
