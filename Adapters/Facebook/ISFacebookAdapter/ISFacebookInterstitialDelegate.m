//
//  ISFacebookInterstitialDelegate.m
//  ISFacebookAdapter
//
//  Created by Hadar Pur on 01/08/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//

#import "ISFacebookInterstitialDelegate.h"

@implementation ISFacebookInterstitialDelegate

- (instancetype)initWithPlacementID:(NSString *)placementID
                        andDelegate:(id<ISFacebookInterstitialDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _placementID = placementID;
        _delegate = delegate;
    }
    return self;
}

/**
 Sent when an FBInterstitialAd successfully loads an ad.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidLoad:_placementID];
}

/**
 Sent when an FBInterstitialAd failes to load an ad.
 @param interstitialAd An FBInterstitialAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)interstitialAd:(FBInterstitialAd *)interstitialAd
      didFailWithError:(NSError *)error {
    
    [_delegate onInterstitialDidFailToLoad:_placementID
                                 withError:error];
}

/**
 Sent immediately before the impression of an FBInterstitialAd object will be logged.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidOpen:_placementID];
}

/**
 Sent after an ad in the FBInterstitialAd object is clicked. The appropriate app store view or app browser will be launched.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidClick:_placementID];
}

/**
 Sent after an FBInterstitialAd object has been dismissed from the screen, returning control to your application.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
    [_delegate onInterstitialDidClose:_placementID];
}


@end
