// Network keys
static NSString * const kAppId                   = @"appId";
static NSString * const kSlotId                 = @"slotId";
static NSString * const kAdapterName              = @"Bigo";

// MetaData
static NSString * const kMetaDataCOPPAKey         = @"LevelPlay_ChildDirected";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
