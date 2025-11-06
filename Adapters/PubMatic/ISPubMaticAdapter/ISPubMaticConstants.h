//
//  ISPubMaticConstants.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

// Network keys
static NSString * const kPublisherId              = @"publisherId";
static NSString * const kProfileId                = @"profileId";
static NSString * const kAdapterName              = @"PubMatic";

// Mediation Keys
static NSString * const kAdUnitId                 = @"adUnitId";
static NSString * const kAppKey                   = @"appKey";
static NSString * const kMediationTokenKey        = @"token";

// MetaData
static NSString * const kMetaDataCOPPAKey         = @"LevelPlay_ChildDirected";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
