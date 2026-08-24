//
//  ISAPSLoadDelegate.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import "ISAPSLoadDelegate.h"
#import "ISAPSAdapter+Internal.h"

@interface ISAPSLoadDelegate ()

@property (nonatomic, weak) id<ISBiddingDataDelegate> delegate;
@property (nonatomic, copy) void (^completionHandler)(DTBAdResponse *adResponse);

@end

@implementation ISAPSLoadDelegate

- (instancetype)initWithDelegate:(id<ISBiddingDataDelegate>)delegate
                      completion:(void (^)(DTBAdResponse *))completion {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _completionHandler = [completion copy];
    }
    return self;
}

- (void)onSuccess:(DTBAdResponse *)adResponse {
    NSString *pricePointEncoded = [adResponse pricePoints:adResponse.adSize];
    NSDictionary *biddingData = @{
        pricePointEncodedKey : pricePointEncoded,
        uuidKey : adResponse.adSize.slotUUID,
        widthKey : @(adResponse.adSize.width),
        heightKey : @(adResponse.adSize.height),
    };

    LogAdapterDelegate_Internal(logToken, pricePointEncoded);
    [self.delegate successWithBiddingData:biddingData];
    self.completionHandler(adResponse);
}

- (void)onFailure:(DTBAdError)error {
    NSString *errorMsg = [self apsErrorWithDTBError:error];
    LogAdapterDelegate_Internal(logError, errorMsg);
    [self.delegate failureWithError:errorMsg];
}

- (NSString *)apsErrorWithDTBError:(DTBAdError)error {
    switch (error) {
        case NETWORK_ERROR:
            return errorNetworkError;
        case NETWORK_TIMEOUT:
            return errorNetworkTimeout;
        case NO_FILL:
            return errorNoFill;
        case INTERNAL_ERROR:
            return errorInternal;
        case REQUEST_ERROR:
            return errorRequest;
        default:
            return errorUnknownError;
    }
}

@end
