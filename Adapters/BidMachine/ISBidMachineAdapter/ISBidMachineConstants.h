//
//  ISBidMachineConstants.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

// Network keys
static NSString * const kSourceId                    = @"sourceId";
static NSString * const kPlacementId                 = @"placementId";
static NSString * const kAdapterName                 = @"BidMachine";

// BidMachine errors
static NSInteger kBidMachineNoFillErrorCode          = 103;

// MetaData
static NSString * const kMetaDataCOPPAKey            = @"BidMachine_COPPA";
static NSString * const kMetaDataCCPANoConsentValue  = @"1YY-";
static NSString * const kMetaDataCCPAConsentValue    = @"1YN-";

static NSString * const kCreativeId                 = @"creativeId";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
