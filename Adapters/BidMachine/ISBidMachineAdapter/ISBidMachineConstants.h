//
//  ISBidMachineConstants.h
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

// Network keys
static NSString * const kSourceId                    = @"sourceId";
static NSString * const kAdapterName                 = @"BidMachine";

// BidMachine errors
static NSInteger kBidMachineNoFillErrorCode          = 103;

// MetaData
static NSString * const kMetaDataCOPPAKey            = @"BidMachine_COPPA";
static NSString * const kMetaDataCCPANoConsentValue  = @"1YY-";
static NSString * const kMetaDataCCPAConsentValue    = @"1YN-";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};
