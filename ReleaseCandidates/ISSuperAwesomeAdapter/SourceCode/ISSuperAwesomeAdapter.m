//
//  ISSuperAwesomeAdapter.m
//  ISSuperAwesomeAdapter
//
//  Created by maoz.elbaz on 20/06/2021.
//

#import "ISSuperAwesomeAdapter.h"
#import "SuperAwesome-Swift.h"
#import "SuperAwesome.h"
#import "AwesomeAds.h"

static NSString * const kAdapterVersion           = SuperAwesomeAdapterVersion;
static NSString * const kSDKVersion               = @"8.1.1";
static NSString * const kAdapterName              = @"SuperAwesome";
static NSString * const kPlacementId              = @"placementId";
static NSString * const kLineItemId               = @"lineItemId";
static NSString * const kCreativeId               = @"creativeId";
static NSString * const kAppId                    = @"appId";
static NSInteger kRVFailedToShowErrorCode         = 101;
static NSInteger kISFailedToShowErrorCode         = 102;

@interface ISSuperAwesomeAdapter (){
    
}


// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementToDelegate;


// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementToDelegate;


@end

@implementation ISSuperAwesomeAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        
        _rewardedVideoPlacementToDelegate = [ConcurrentMutableDictionary dictionary];
        
        _interstitialPlacementToDelegate  = [ConcurrentMutableDictionary dictionary];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return kSDKVersion;
}

- (NSString *)sdkName {
    return kAdapterName;
}

#pragma mark - Rewarded Video

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.rewardedVideoPlacementToDelegate setObject:delegate forKey:placementId];
    
    [self initSDK:adapterConfig];
    [delegate adapterRewardedVideoInitSuccess];
    
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = adapterConfig.settings[kPlacementId];
        
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        
        // check if ad is loaded
        if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
            
            // display the ad
            [SAVideoAd play: placementId.intValue fromVC: viewController];
        } else {
            NSError *error = [ISError createError:kRVFailedToShowErrorCode withMessage:@"rewarded video hasAdAvailable = NO"];
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        
    });
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* jsonDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *placementId = [jsonDic objectForKey:kPlacementId];
    NSString *lineItemId = [jsonDic objectForKey:kLineItemId];
    NSString *creativeId = [jsonDic objectForKey:kCreativeId];
    NSString *missingParamName = nil;
    
    if(placementId == nil ) missingParamName = kPlacementId;
    else if(lineItemId == nil ) missingParamName = kLineItemId;
    else if(creativeId == nil ) missingParamName = kCreativeId;

    if(missingParamName != nil) {
        NSError *error = [self errorForMissingCredentialFieldWithName:missingParamName];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [SAVideoAd setCallback:^(NSInteger placementId, SAEvent event) {


        NSString *pId = [NSString stringWithFormat: @"%ld", (long)placementId];
        LogAdapterDelegate_Internal(@"placementId = %@ event = %ld", pId,(long)event);
        
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementToDelegate objectForKey:pId];

        switch (event) {
            case adLoaded:
            case adAlreadyLoaded: {
                [delegate adapterRewardedVideoHasChangedAvailability:YES];
                break;
            }
            case adEmpty: {
                // called when the request was successful but the ad server returned no ad
                NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_RV_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"SuperAwesome no fill"}];
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                [delegate adapterRewardedVideoDidFailToLoadWithError:error];
                break;
            }
            case adFailedToLoad: {
                // called when an ad could not be loaded
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                break;
            }

            case adShown: {
                // called when an ad is first shown
                [delegate adapterRewardedVideoDidOpen];
                [delegate adapterRewardedVideoDidStart];
                break;
            }
            case adFailedToShow: {
                // called when an ad fails to show
                NSError *error = [ISError createError:kRVFailedToShowErrorCode withMessage:@"rewarded video adFailedToShow"];
                [delegate adapterRewardedVideoDidFailToShowWithError:error];
                break;
            }
            case adClicked: {
                // called when an ad is clicked
                [delegate adapterRewardedVideoDidClick];

                break;
            }
            case adEnded: {
                // called when a video ad has ended playing (but hasn't yet closed)
                [delegate adapterRewardedVideoDidEnd];
                [delegate adapterRewardedVideoDidReceiveReward];

                break;
            }
            case adClosed: {
                // called when a fullscreen ad is closed
                [delegate adapterRewardedVideoDidClose];
                break;
            }
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [SAVideoAd load:placementId.intValue creativeId:creativeId.intValue lineItemId:lineItemId.intValue];
    });
    
}


- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [SAVideoAd hasAdAvailable: placementId.intValue];
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Interstitial



- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }

    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.interstitialPlacementToDelegate setObject:delegate forKey:placementId];
    
    [self initSDK:adapterConfig];
    [delegate adapterInterstitialInitSuccess];
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* jsonDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *placementId = [jsonDic objectForKey:kPlacementId];
    NSString *lineItemId = [jsonDic objectForKey:kLineItemId];
    NSString *creativeId = [jsonDic objectForKey:kCreativeId];
    NSString *missingParamName = nil;
    if(placementId == nil ) missingParamName = kPlacementId;
    if(lineItemId == nil ) missingParamName = kLineItemId;
    if(creativeId == nil ) missingParamName = kCreativeId;

    if(missingParamName != nil) {
        NSError *error = [self errorForMissingCredentialFieldWithName:missingParamName];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [SAInterstitialAd setCallback:^(NSInteger placementId, SAEvent event) {


        NSString *pId = [NSString stringWithFormat: @"%ld", (long)placementId];
        LogAdapterDelegate_Internal(@"placementId = %@ event = %ld", pId,(long)event);
        
        id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementToDelegate objectForKey:pId];

        switch (event) {
            case adLoaded:
            case adAlreadyLoaded: {
                [delegate adapterInterstitialDidLoad];
                break;
            }
            case adEmpty: {
                // called when the request was successful but the ad server returned no ad
                NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_IS_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"SuperAwesome no fill"}];
                [delegate adapterInterstitialDidFailToLoadWithError:error];
                break;
            }
            case adFailedToLoad: {
                // called when an ad could not be loaded
                NSError *error =[NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{@"Error reason":@"adFailedToLoad"}];
                [delegate adapterInterstitialDidFailToLoadWithError:error];
                break;
            }

            case adShown: {
                // called when an ad is first shown
                [delegate adapterInterstitialDidOpen];
                [delegate adapterInterstitialDidShow];
                break;
            }
            case adFailedToShow: {
                // called when an ad fails to show
                NSError *error = [ISError createError:kISFailedToShowErrorCode withMessage:@"interstitial adFailedToShow"];
                [delegate adapterInterstitialDidFailToShowWithError:error];
                break;
            }
            case adClicked: {
                // called when an ad is clicked
                [delegate adapterInterstitialDidClick];

                break;
            }
            case adEnded: {
                // called when a video ad has ended playing (but hasn't yet closed)

                break;
            }
            case adClosed: {
                // called when a fullscreen ad is closed
                [delegate adapterInterstitialDidClose];
                break;
            }
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [SAInterstitialAd loadAdByPlacementId:placementId.intValue andLineItem:lineItemId.intValue andCreativeId:creativeId.intValue];
    });
    
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = adapterConfig.settings[kPlacementId];
        
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        
        // check if ad is loaded
        if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
            
            // display the ad
            [SAInterstitialAd play: placementId.intValue fromVC: viewController];
        } else {
            NSError *error = [ISError createError:kISFailedToShowErrorCode withMessage:@"interstitial hasAdAvailable = NO"];
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
        
    });
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [SAInterstitialAd hasAdAvailable: placementId.intValue];
}

- (NSDictionary *)getBiddingData {
    return @{};
}


#pragma mark - Private Methods

- (void)initSDK:(ISAdapterConfig *)adapterConfig {
    LogAdapterDelegate_Info(@"");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL logLevel =[ISConfigurations getConfigurations].adaptersDebug;
        [AwesomeAds initSDK:logLevel];
    });
}
@end
