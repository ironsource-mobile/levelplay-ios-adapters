//
//  ISVungleConstant.h
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

// Mediation keys
static NSString * const kMediationName          = @"ironsource";

// Network keys
static NSString * const kAdapterName            = @"Vungle";
static NSString * const kAppId                  = @"AppID";
static NSString * const kPlacementId            = @"PlacementId";

// Meta data flags
static NSString * const kMetaDataCOPPAKey       = @"Vungle_COPPA";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
