//
//  ISVerveConstants.h
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

// Network keys
static NSString * const kAppToken                    = @"appToken";
static NSString * const kZoneId                      = @"zoneId";
static NSString * const kAdapterName                 = @"Verve";
static NSString * const kMediation                   = @"lp";
static NSString * const kMediationTokenKey           = @"token";

// MetaData
static NSString * const kMetaDataCOPPAKey            = @"LevelPlay_ChildDirected";
static NSString * const kMetaDataCCPAConsentValue    = @"1YY-";
static NSString * const kMetaDataCCPANoConsentValue  = @"1YN-";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
