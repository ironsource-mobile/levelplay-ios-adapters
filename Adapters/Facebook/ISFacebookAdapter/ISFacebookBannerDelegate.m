//
//  ISFacebookBannerDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISFacebookBannerDelegate.h>

@implementation ISFacebookBannerDelegate

- (instancetype)initWithPlacementID:(NSString *)placementID
                        andDelegate:(id<ISFacebookBannerDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _placementID = placementID;
        _delegate = delegate;
    }
    return self;
}

/**
 Sent when an ad has been successfully loaded.
 @param adView An FBAdView object sending the message.
 */
- (void)adViewDidLoad:(FBAdView *)adView {
    [_delegate onBannerDidLoad:_placementID
                    bannerView:adView];
}

/**
 Sent after an FBAdView fails to load the ad.
 @param adView An FBAdView object sending the message.
 @param error An error object containing details of the error.
 */
- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    [_delegate onBannerDidFailToLoad:_placementID
                           withError:error];
}

/**
 Sent immediately before the impression of an FBAdView object will be logged.
 @param adView An FBAdView object sending the message.
 */
- (void)adViewWillLogImpression:(FBAdView *)adView {
    [_delegate onBannerDidShow:_placementID];
}

/**
 Sent after an ad has been clicked by the person.
 @param adView An FBAdView object sending the message.
 */
- (void)adViewDidClick:(FBAdView *)adView {
    [_delegate onBannerDidClick:_placementID];
}

@end
