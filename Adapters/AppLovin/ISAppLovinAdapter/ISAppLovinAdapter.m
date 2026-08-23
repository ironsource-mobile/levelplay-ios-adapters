//
//  ISAppLovinAdapter.m
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISMetaDataUtils.h>
#import <IronSource/ISConfigurations.h>
#import <IronSource/ISConcurrentMutableSet.h>
#import "ISAppLovinAdapter+Internal.h"

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initializationDelegates = nil;

@implementation ISAppLovinAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return AppLovinAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [ALSdk version];
}

+ (NSString *)networkAdapterVersion {
    return AppLovinAdapterVersion;
}

#pragma mark - Initialization Methods And Callbacks

- (instancetype)init {
    self = [super init];
    if (self) {
        if (initializationDelegates == nil) {
            initializationDelegates = [ISConcurrentMutableSet<ISNetworkInitializationDelegate> set];
        }
    }
    return self;
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    NSString *sdkKey = [adData getString:sdkKeyKey];
    NSString *zoneId = [adData getString:zoneIdKey];

    // Configuration Validation
    if (!sdkKey || sdkKey.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, sdkKeyKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!zoneId || zoneId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, zoneIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (initState == INIT_STATE_SUCCESS) {
        [delegate onInitDidSucceed];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initializationDelegates addObject:delegate];
    }

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        LogAdapterApi_Internal(logSdkKeyAndZoneId, sdkKey, zoneId);

        ISAppLovinAdapter * __weak weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            ALSdkInitializationConfiguration *initConfig =
                [ALSdkInitializationConfiguration configurationWithSdkKey:sdkKey
                                                            builderBlock:^(ALSdkInitializationConfigurationBuilder *builder) {
                builder.mediationProvider = ALMediationProviderIronsource;
            }];

            [ALSdk shared].settings.verboseLoggingEnabled = [ISConfigurations getConfigurations].adaptersDebug;

            LogAdapterApi_Internal(logSdkKeyAndVerboseLogging, sdkKey, [ALSdk shared].settings.isVerboseLoggingEnabled);

            // AppLovin's initialization callback currently doesn't give any indication to initialization failure.
            // Once this callback is called we will treat the initialization as successful
            [[ALSdk shared] initializeWithConfiguration:initConfig
                                      completionHandler:^(ALSdkConfiguration *sdkConfig) {
                __typeof__(self) strongSelf = weakSelf;
                [strongSelf initializationSuccess];
            }];
        });
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(logInitSuccess);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initializationDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initializationDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }

    // this is an array of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(logMetaDataSet, key, value);

    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
    }
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    [ALPrivacySettings setHasUserConsent:consent];
}

- (void)setCCPAValue:(BOOL)ccpa {
    LogAdapterApi_Internal(logCCPA, ccpa ? @"YES" : @"NO");
    [ALPrivacySettings setDoNotSell:ccpa];
}

#pragma mark - Helper Methods

+ (NSString *)errorMessageForCode:(int)code {
    switch (code) {
        case kALErrorCodeSdkDisabled:                       return errorSdkDisabled;
        case kALErrorCodeNoFill:                            return errorNoFill;
        case kALErrorCodeAdRequestNetworkTimeout:           return errorNetworkTimeout;
        case kALErrorCodeNotConnectedToInternet:            return errorNotConnected;
        case kALErrorCodeAdRequestUnspecifiedError:         return errorUnspecified;
        case kALErrorCodeUnableToRenderAd:                  return errorUnableToRender;
        case kALErrorCodeInvalidZone:                       return errorInvalidZone;
        case kALErrorCodeInvalidAdToken:                    return errorInvalidAdToken;
        case kALErrorCodeUnableToPrecacheResources:         return errorPrecacheResources;
        case kALErrorCodeUnableToPrecacheImageResources:    return errorPrecacheImage;
        case kALErrorCodeUnableToPrecacheVideoResources:    return errorPrecacheVideo;
        case kALErrorCodeInvalidResponse:                   return errorInvalidResponse;
        case kALErrorCodeIncentiviziedAdNotPreloaded:       return errorNotPreloaded;
        case kALErrorCodeIncentivizedUnknownServerError:    return errorUnknownServer;
        case kALErrorCodeIncentivizedValidationNetworkTimeout: return errorValidationTimeout;
        case kALErrorCodeIncentivizedUserClosedVideo:       return errorUserClosedVideo;
        case kALErrorCodeInvalidURL:                        return errorInvalidURL;
        case kALErrorCodeUnableToPrecacheHTMLResources:     return errorPrecacheHTML;
        case kALErrorCodeInvalidBody:                       return errorInvalidBody;
        default:                                            return [NSString stringWithFormat:errorUnknownCode, code];
    }
}

@end
