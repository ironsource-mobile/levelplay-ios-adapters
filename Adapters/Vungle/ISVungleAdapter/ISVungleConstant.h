//
//  ISVungleConstant.h
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

// Mediation keys
static NSString * const kMediationName          = @"ironsource";

// Network keys
static NSString * const kAdapterName            = @"Vungle";
static NSString * const kAppId                  = @"AppID";
static NSString * const kPlacementId            = @"PlacementId";
static NSString * const kCreativeId             = @"creativeId";

// Meta data flags
static NSString * const kMetaDataCOPPAKey       = @"Vungle_COPPA";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
