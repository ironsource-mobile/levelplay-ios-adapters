//
//  ISSmaatoAdapter.m
//  ISSmaatoAdapter
//
//  Created by Hadar Pur on 04/11/2020.
//

#import "ISSmaatoAdapter.h"
#import <SmaatoSDKCore/SmaatoSDKCore.h>
#import <SmaatoSDKBanner/SmaatoSDKBanner.h>
#import <SmaatoSDKInAppBidding/SMAInAppBidding.h>
#import <SmaatoSDKInAppBidding/SMAInAppBid.h>

static NSString * const kAdapterVersion     = SmaatoAdapterVersion;
static NSString * const kAdSpaceID          = @"adspaceID";
static NSString * const kPublisherID        = @"publisherId";
static NSString * const kAdapterName        = @"Smaato";
static NSString * const kCCPAKey            = @"IABUSPrivacy_String";

static int const kNoFillErrorCode           = 204;

@interface ISSmaatoAdapter () <SMABannerViewDelegate>

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerToAdSpaceId;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerViewControllerToAdSpaceId;

@end

@implementation ISSmaatoAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        // Banner
        _bannerToSmashDelegate                  = [ConcurrentMutableDictionary dictionary];
        _bannerToAdSpaceId                      = [ConcurrentMutableDictionary dictionary];
        _bannerViewControllerToAdSpaceId        = [ConcurrentMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [SmaatoSDK sdkVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AVFoundation", @"CoreMedia", @"CoreTelephony", @"SafariServices", @"StoreKit", @"SystemConfiguration", @"WebKit"];
}

- (NSString *)sdkName {
    return @"SmaatoSDK";
}

- (void) setMetaDataWithKey:(NSString *)key
                  andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    }
}

- (void) setCCPAValue:(BOOL)doNotSell {
    NSString *ccpaValue = doNotSell ? @"1YYN" : @"1YNN";
    LogAdapterApi_Internal(@"key = %@, value = %@", kCCPAKey, ccpaValue);
    [NSUserDefaults.standardUserDefaults setObject:ccpaValue
                                            forKey:kCCPAKey];
}

#pragma mark - Banner API

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return @{};
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *publisherID = adapterConfig.settings[kPublisherID];

    // verify that the publisherID is not empty
    if (![self isConfigValueValid:publisherID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPublisherID];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"publisherID = %@", publisherID);

    // initialize smaato sdk
    [self initSDKWithPublisherId:publisherID];
    
    // call init success
    [delegate adapterBannerInitSuccess];
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData viewController:(UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *placementID = adapterConfig.settings[kAdSpaceID];
    
    // verify that the placementID is not empty
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAdSpaceID];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);

    // add delegate to dictionary
    [_bannerToSmashDelegate setObject:delegate forKey:placementID];
    
    // add vc to dictionary
    [_bannerViewControllerToAdSpaceId setObject:viewController forKey:placementID];
    
    // get banner size
    SMABannerAdSize bannerSize = [self getBannerSize:size];
    CGRect bannerViewFrame = [self getBannerRect:size];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //create banner view
        SMABannerView *bannerView = [[SMABannerView alloc] initWithFrame:bannerViewFrame];
        bannerView.autoreloadInterval = kSMABannerAutoreloadIntervalDisabled;
        bannerView.delegate = self;

        // add banner view to the dictionary
        [self.bannerToAdSpaceId setObject:bannerView forKey:placementID];
        
        // build ad req
        SMAAdRequestParams *adRequestParams = [self getAdRequestWithServerData:serverData];
        
        if (adRequestParams != nil) {
            [bannerView loadWithAdSpaceId:placementID adSize:bannerSize requestParams:adRequestParams];
        } else {
            NSError* error = [NSError errorWithDomain:kAdapterName code:ERROR_BN_LOAD_EXCEPTION
                        userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Got an error while creating Smaato AdRequestParams"]}];
            LogAdapterApi_Error(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementID = adapterConfig.settings[kAdSpaceID];
    LogAdapterApi_Internal(@"placementID = %@", placementID);

    SMABannerView *bannerView = [_bannerToAdSpaceId objectForKey:placementID];
    
    if (bannerView != nil) {
        
        // remove banner from the dictionary
        [_bannerToAdSpaceId removeObjectForKey:placementID];
        [_bannerToSmashDelegate removeObjectForKey:placementID];
        [_bannerViewControllerToAdSpaceId removeObjectForKey:placementID];
    }
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}

#pragma mark - Banner Callbacks

/**
 A view controller that will be used to present modal view controllers.
 
 @param bannerView  The banner view sending the message.
 @return            A presenting view controller.
 */
- (UIViewController *)presentingViewControllerForBannerView:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    UIViewController *containerViewController = [_bannerViewControllerToAdSpaceId objectForKey:bannerView.adSpaceId];
    return containerViewController;
}

/**
 Sent when the banner view loads an ad successfully.
 
 @param bannerView The banner view sending the message.
 */
- (void)bannerViewDidLoad:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    id<ISBannerAdapterDelegate> bannerDelegate = [_bannerToSmashDelegate objectForKey:bannerView.adSpaceId];
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidLoad:bannerView];
    }
}

/**
 Sent when the banner view fails to load an ad successfully.
 
 @param bannerView  The banner view sending the message.
 @param error       An error object containing details of why the banner view failed to load an ad.
 */
- (void)bannerView:(SMABannerView *_Nonnull)bannerView didFailWithError:(NSError *_Nonnull)error {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    id<ISBannerAdapterDelegate> bannerDelegate = [_bannerToSmashDelegate objectForKey:bannerView.adSpaceId];

    if (bannerDelegate) {
        
        NSInteger errorCode = error.code;
        NSString *errorMessage = error.description;

        if (error.code == kNoFillErrorCode) { // no fill
            errorCode = ERROR_BN_LOAD_NO_FILL;
        }
        
        NSError *innerError = [[NSError alloc] initWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        LogAdapterDelegate_Internal(@"innerError = %@", innerError);

        [bannerDelegate adapterBannerDidFailToLoadWithError:innerError];
    }
}

/**
 Sent when the ad view impression has been tracked by the sdk.
 
 @param bannerView  The banner view sending the message.
 */
- (void)bannerViewDidImpress:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    id<ISBannerAdapterDelegate> bannerDelegate = [_bannerToSmashDelegate objectForKey:bannerView.adSpaceId];
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidShow];
    }
}

/**
 Sent when banner view is clicked.
 
 @param bannerView  The banner view sending the message.
 */
- (void)bannerViewDidClick:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    id<ISBannerAdapterDelegate> bannerDelegate = [_bannerToSmashDelegate objectForKey:bannerView.adSpaceId];
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidClick];
    }
}

/**
 Sent when the ad causes the user to leave the application.
 
 @param bannerView  The banner view sending the message.
 */
- (void)bannerWillLeaveApplicationFromAd:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    id<ISBannerAdapterDelegate> bannerDelegate = [_bannerToSmashDelegate objectForKey:bannerView.adSpaceId];
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerWillLeaveApplication];
    }
}

/**
 Sent when the user taps on an ad and modal content will be presented (e.g. internal browser).
 
 @param bannerView  The banner view sending the message.
 */
- (void)bannerViewWillPresentModalContent:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    id<ISBannerAdapterDelegate> bannerDelegate = [_bannerToSmashDelegate objectForKey:bannerView.adSpaceId];
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerWillPresentScreen];
    }
}

/**
 Sent when modal content will be dismissed.
 
 @param bannerView  The banner view sending the message.
 */
- (void)bannerViewDidDismissModalContent:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
    id<ISBannerAdapterDelegate> bannerDelegate = [_bannerToSmashDelegate objectForKey:bannerView.adSpaceId];
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidDismissScreen];
    }
}

/**
 Sent when modal content has been presented.
 
 @param bannerView  The banner view sending the message.
 */
- (void)bannerViewDidPresentModalContent:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
}

/**
 Sent when TTL has expired, based on the timestamp from the SOMA header.
 
 @param bannerView  The banner view sending the message.
 */
- (void)bannerViewDidTTLExpire:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"pacementId = %@", bannerView.adSpaceId);
}

#pragma mark - Private Methods

- (void)initSDKWithPublisherId:(NSString *)publisherId {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // initialize SDK first!
        SMAConfiguration *config = [[SMAConfiguration alloc] initWithPublisherId:publisherId];

        if ([ISConfigurations getConfigurations].adaptersDebug) {
            // log errors only
            config.logLevel = kSMALogLevelDebug;
        }

        [SmaatoSDK initSDKWithConfig:config];
    });
}

- (SMABannerAdSize) getBannerSize:(ISBannerSize *)size {
    SMABannerAdSize smaatoSize = kSMABannerAdSizeAny;

    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        smaatoSize = kSMABannerAdSizeXXLarge_320x50;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        smaatoSize = kSMABannerAdSizeMediumRectangle_300x250;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            smaatoSize = kSMABannerAdSizeLeaderboard_728x90;
        } else {
            smaatoSize = kSMABannerAdSizeXXLarge_320x50;
        }
    }
    
    return smaatoSize;
}

- (CGRect)getBannerRect:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return CGRectMake(0, 0, 320, 50);
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CGRectMake(0, 0, 300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, 728, 90);
        }
        else {
            return CGRectMake(0, 0, 320, 50);
        }
    }
    
    return CGRectMake(0, 0, 0, 0);
}

- (SMAAdRequestParams *) getAdRequestWithServerData:(NSString *)serverData {
    SMAAdRequestParams *adRequestParams;
    NSError *error;
    
    // converting serverData to NSData
    NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
        
    // create Smaato IAB
    SMAInAppBid *inAppBid = [SMAInAppBid bidWithResponseData:data];
        
    // get the unique id for the load req
    NSString *uniqueId = [SMAInAppBidding saveBid:inAppBid error:&error];
        
    if (error == nil) {
        // build ad req
        adRequestParams = [SMAAdRequestParams new];
        adRequestParams.ubUniqueId = uniqueId;
    }
    
    return adRequestParams;
}

@end
