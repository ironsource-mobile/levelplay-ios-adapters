//  
//  ISYandexConstants.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//


// Network keys
static NSString * const kAppId                    = @"appId";
static NSString * const kAdUnitId                 = @"adUnitId";
static NSString * const kMediationName            = @"ironsource";
static NSString * const kAdapterName              = @"Yandex";
static NSString * const kCreativeId               = @"creativeId";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
