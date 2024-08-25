//
//  ISFacebookInterstitialDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import "ISFacebookInterstitialDelegate.h"
#import "ISFacebookConstants.h"

@implementation ISFacebookInterstitialDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}

/**
 Sent when an FBInterstitialAd successfully loads an ad.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidLoad];
}

/**
 Sent when an FBInterstitialAd failes to load an ad.
 @param interstitialAd An FBInterstitialAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)interstitialAd:(FBInterstitialAd *)interstitialAd
      didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);

    NSInteger errorCode;
    NSString *errorReason;

    if (error) {
        errorCode = error.code == kMetaNoFillErrorCode ? ERROR_IS_LOAD_NO_FILL : error.code;
        errorReason = error.description;
    } else {
        errorCode = ERROR_CODE_GENERIC;
        errorReason = @"Load attempt failed";
    }
    
    NSError *interstitialError = [NSError errorWithDomain:kAdapterName
                                                     code:errorCode
                                                 userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    
    [self.delegate adapterInterstitialDidFailToLoadWithError:interstitialError];
}

/**
 Sent immediately before the impression of an FBInterstitialAd object will be logged.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

/**
 Sent after an ad in the FBInterstitialAd object is clicked. The appropriate app store view or app browser will be launched.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidClick];
}

/**
 Sent after an FBInterstitialAd object has been dismissed from the screen, returning control to your application.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidClose];
}

@end
