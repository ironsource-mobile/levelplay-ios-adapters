//
//  ISMolocoConstants.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

// Network keys
static NSString * const kAppKey                   = @"appKey";
static NSString * const kAdUnitId                 = @"adUnitId";
static NSString * const kAdapterName              = @"Moloco";

// Mediation info
static NSString * const kMediationInfo            = @"LevelPlay";

// MetaData
static NSString * const kMetaDataCOPPAKey         = @"Moloco_COPPA";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};