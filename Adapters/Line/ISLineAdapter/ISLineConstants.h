//
//  ISLineConstants.h
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

// Network keys
static NSString * const kAppId                    = @"appId";
static NSString * const kSlotId                   = @"slotId";
static NSString * const kAdapterName              = @"Line";
static NSString * const kMediationTokenKey        = @"token";


// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED,
};
