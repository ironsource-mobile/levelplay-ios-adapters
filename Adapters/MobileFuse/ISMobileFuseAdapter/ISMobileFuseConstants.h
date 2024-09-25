// Network keys
static NSString * const kPlacementId            = @"placementId";
static NSString * const kAdapterName            = @"MobileFuse";

// MetaData
static NSString * const kMetaDataCOPPAKey       = @"LevelPlay_ChildDirected";
static NSString * const KDoNotSellYesValue           = @"1YY-";
static NSString * const KDoNotSellNoValue            = @"1YN-";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// See MobileFuse SDK error codes here: https://docs.mobilefuse.com/docs/error-codes
typedef NS_ENUM(NSInteger, MobileFuseAdErrorCode)
{
    MobileFuseAlreadyLoaded = 1,
    MobileFuseRuntimeError = 3,
    MobileFuseAlreadyRendered = 4,
    MobileFuseLoadError = 5
};
