//  
//  ISYandexConstants.h
//  ISYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//


// Network keys
static NSString * const kAppId                    = @"appId";
static NSString * const kAdUnitId                 = @"adUnitId";
static NSString * const kMediationName            = @"ironsource";
static NSString * const kAdapterName              = @"Yandex";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
