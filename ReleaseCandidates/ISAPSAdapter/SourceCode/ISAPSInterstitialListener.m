//
//  ISLiftoffInterstitialListener.m
//  ISAPSAdapter
//
//  Created by Sveta Itskovich on 14/12/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISAPSInterstitialListener.h"

@implementation ISAPSInterstitialListener

/// Sent when an interstitial ad has loaded.
- (instancetype)initWithPlacementID:(NSString *)placementID andDelegate:(id<ISAPSISDelegateWrapper>)delegate{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _placementID = placementID;
    }
    return self;
}

/// Sent when an interstitial ad has loaded.
- (void)interstitialDidLoad:(DTBAdInterstitialDispatcher * _Nullable)interstitial {
    [_delegate interstitialDidLoad:_placementID];
    
}

/// Sent when banner ad has failed to load.
- (void)interstitial:(DTBAdInterstitialDispatcher * _Nullable )interstitial didFailToLoadAdWithErrorCode:(DTBAdErrorCode)errorCode{
    [_delegate interstitial:_placementID didFailToLoadAdWithErrorCode:errorCode];
}

/// Sent when an interstitial is about to be shown.
- (void)interstitialWillPresentScreen:(DTBAdInterstitialDispatcher * _Nullable )interstitial{
}

/// Sent when an interstitial is about to be shown.
- (void)interstitialDidPresentScreen:(DTBAdInterstitialDispatcher * _Nullable )interstitial{
    [_delegate interstitialDidPresentScreen:_placementID];
}

/// Sent when an interstitial is about to be dismissed.
- (void)interstitialWillDismissScreen:(DTBAdInterstitialDispatcher * _Nullable )interstitial{
}

/// Sent when an interstitial has been dismissed.
- (void)interstitialDidDismissScreen:(DTBAdInterstitialDispatcher * _Nullable )interstitial{
    [_delegate interstitialDidDismissScreen:_placementID];
}

/// Sent when an interstitial is clicked and an external application is launched.
- (void)interstitialWillLeaveApplication:(DTBAdInterstitialDispatcher * _Nullable )interstitial{
}

- (void)showFromRootViewController:(UIViewController *_Nonnull)controller{
}

- (void)impressionFired{
    [_delegate interstitialImpressionFired:_placementID];
}

@end
