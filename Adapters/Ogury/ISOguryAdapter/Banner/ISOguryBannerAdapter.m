//
//  ISOguryBannerAdapter.m
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OgurySdk/Ogury.h>
#import <OguryAds/OguryAds.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISOguryBannerAdapter.h"
#import "ISOguryBannerDelegate.h"
#import "ISOguryAdapter+Internal.h"
#import "ISOguryAdapter.h"
#import "ISOguryConstants.h"

@interface ISOguryBannerAdapter ()

@property (nonatomic, strong) OguryBannerAdView      *bannerAdView;
@property (nonatomic, strong) ISOguryBannerDelegate  *bannerAdViewDelegate;

@end

@implementation ISOguryBannerAdapter

#pragma mark - Banner Methods

- (void)loadAdWithAdData:(ISAdData *)adData
          viewController:(UIViewController *)viewController
                    size:(ISBannerSize *)size
                delegate:(id<ISBannerAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    OguryBannerAdSize *bannerSize = [self getBannerSize:size];
    if (bannerSize == nil) {
        NSError *error = [ISError errorWithDomain:networkName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:logUnsupportedBannerSize}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    self.bannerAdViewDelegate = [[ISOguryBannerDelegate alloc] initWithDelegate:delegate];

    OguryMediation *mediation = [[OguryMediation alloc] initWithName:mediationName
                                                            version:[LevelPlay sdkVersion]
                                                     adapterVersion:OguryAdapterVersion];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.bannerAdView = [[OguryBannerAdView alloc] initWithAdUnitId:adUnitId
                                                                   size:bannerSize
                                                              mediation:mediation];
        self.bannerAdView.delegate = self.bannerAdViewDelegate;
        self.bannerAdView.frame = CGRectMake(0, 0, size.width, size.height);
        [self.bannerAdView loadWithAdMarkup:adData.serverData];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bannerAdView destroy];
        self.bannerAdView = nil;
        self.bannerAdViewDelegate = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISOguryAdapter *adapter = (ISOguryAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

- (OguryBannerAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:sizeBanner]) {
        return OguryBannerAdSize.small_banner_320x50;
    } else if ([size.sizeDescription isEqualToString:sizeRectangle]) {
        return OguryBannerAdSize.mrec_300x250;
    } else if ([size.sizeDescription isEqualToString:sizeSmart] &&
               [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        return OguryBannerAdSize.small_banner_320x50;
    }
    return nil;
}

@end
