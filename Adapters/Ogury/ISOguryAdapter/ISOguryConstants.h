// Network keys
static NSString * const kAppId                   = @"assetKey";
static NSString * const kPlacementId             = @"adUnitId";
static NSString * const kAdapterName             = @"Ogury";

// Mediation keys
static NSString * const kMediationName           = @"Unity LevelPlay";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};
