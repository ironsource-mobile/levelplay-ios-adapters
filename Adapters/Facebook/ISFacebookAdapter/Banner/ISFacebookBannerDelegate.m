//
//  ISFacebookBannerDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import "ISFacebookBannerDelegate.h"
#import "ISFacebookConstants.h"

@implementation ISFacebookBannerDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}

/**
 Sent when an ad has been successfully loaded.
 @param adView An FBAdView object sending the message.
 */
- (void)adViewDidLoad:(FBAdView *)adView {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidLoad:adView];
}

/**
 Sent after an FBAdView fails to load the ad.
 @param adView An FBAdView object sending the message.
 @param error An error object containing details of the error.
 */
- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error);

    NSInteger errorCode;
    NSString *errorReason;

    if (error) {
        errorCode = error.code == kMetaNoFillErrorCode ? ERROR_BN_LOAD_NO_FILL : error.code;
        errorReason = error.description;
    } else {
        errorCode = ERROR_CODE_GENERIC;
        errorReason = @"Load attempt failed";
    }
    
    NSError *bannerError = [NSError errorWithDomain:kAdapterName
                                               code:errorCode
                                           userInfo:@{NSLocalizedDescriptionKey:errorReason}];

    [self.delegate adapterBannerDidFailToLoadWithError:bannerError];
}

/**
 Sent immediately before the impression of an FBAdView object will be logged.
 @param adView An FBAdView object sending the message.
 */
- (void)adViewWillLogImpression:(FBAdView *)adView {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidShow];
}

/**
 Sent after an ad has been clicked by the person.
 @param adView An FBAdView object sending the message.
 */
- (void)adViewDidClick:(FBAdView *)adView {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidClick];
}

@end
