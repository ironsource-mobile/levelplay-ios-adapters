//
//  ISVoodooConstants.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

// Network keys
static NSString * const kAdapterName          = @"Voodoo";
static NSString * const kPlacementId          = @"placementId";

// Mediation Keys
static NSString * const kMediationName        = @"ironsource";
static NSString * const kMediationTokenKey    = @"token";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
