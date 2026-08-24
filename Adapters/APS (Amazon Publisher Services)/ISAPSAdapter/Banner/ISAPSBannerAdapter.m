//
//  ISAPSBannerAdapter.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISAPSBannerAdapter.h"
#import "ISAPSBannerDelegate.h"
#import "ISAPSAdapter+Internal.h"

@interface ISAPSBannerAdapter ()

@property (nonatomic, strong) DTBAdBannerDispatcher *bannerAdView;
@property (nonatomic, strong) ISAPSBannerDelegate *bannerAdDelegate;
@property (nonatomic, strong, nullable) DTBAdResponse *adResponse;

@end

@implementation ISAPSBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    if (!self.adResponse) {
        LogAdapterApi_Internal(logError, logAdResponseMissing);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:logAdResponseMissing];
        return;
    }

    CGRect bannerRect = [self getBannerRectSize:size];

    if (CGRectIsEmpty(bannerRect)) {
        NSError *error = [ISError createErrorWithDomain:networkName
                                                   code:ERROR_BN_UNSUPPORTED_SIZE
                                                message:logUnsupportedBannerSize];
        LogAdapterApi_Internal(logError, error.description);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    LogAdapterApi_Internal(logUuid, self.adResponse.adSize.slotUUID);

    self.bannerAdDelegate = [[ISAPSBannerDelegate alloc] initWithDelegate:delegate];

    NSDictionary *mediationHints = self.adResponse.mediationHints;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView = [[DTBAdBannerDispatcher alloc] initWithAdFrame:bannerRect
                                                              delegate:self.bannerAdDelegate];
        [self.bannerAdView fetchBannerAdWithParameters:mediationHints];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView = nil;
        self.bannerAdDelegate = nil;
        self.adResponse = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    NSDictionary *dimensions = adData.configuration[dimensionsKey];
    NSInteger width = [dimensions[widthDimensionKey] integerValue];
    NSInteger height = [dimensions[heightDimensionKey] integerValue];

    if (width <= 0 || height <= 0) {
        NSString *errorMessage = [NSString stringWithFormat:logInvalidAdSize, (long)width, (long)height];
        LogAdapterApi_Error(logError, errorMessage);
        [delegate failureWithError:errorMessage];
        return;
    }

    NSString *uuid = [adData getString:uuidKey];

    if (!uuid) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingConfigurationParam, uuidKey];
        LogAdapterApi_Error(logError, errorMessage);
        [delegate failureWithError:errorMessage];
        return;
    }

    ISAPSAdapter *adapter = (ISAPSAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Error(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    DTBAdSize *adSize = [[DTBAdSize alloc] initBannerAdSizeWithWidth:width
                                                              height:height
                                                         andSlotUUID:uuid];

    __weak typeof(self) weakSelf = self;
    [adapter collectBiddingInfoWithSize:adSize
                               delegate:delegate
                             completion:^(DTBAdResponse *adResponse) {
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.adResponse = adResponse;
    }];
}

- (CGRect)getBannerRectSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return CGRectMake(0, 0, bannerWidth, bannerHeight);
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return CGRectMake(0, 0, rectangleWidth, rectangleHeight);
    } else if ([size.sizeDescription isEqualToString:sizeSmart]) {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, leaderboardWidth, leaderboardHeight);
        } else {
            return CGRectMake(0, 0, bannerWidth, bannerHeight);
        }
    }

    return CGRectZero;
}

@end
