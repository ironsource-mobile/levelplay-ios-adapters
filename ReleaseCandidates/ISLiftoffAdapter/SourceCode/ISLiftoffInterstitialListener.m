//
//  ISLiftoffInterstitialListener.m
//  ISLiftoffAdapter
//
//  Created by Roi Eshel on 14/09/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISLiftoffInterstitialListener.h"

@implementation ISLiftoffInterstitialListener

- (instancetype)initWithDelegate:(id<ISLiftoffInterstitialDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}


// Called when the interstitial ad request is successfully filled.
- (void)loInterstitialDidLoad:(LOInterstitial *)interstitial {
    [_delegate onInterstitialLoadSuccess:interstitial];
}

// Called when the interstitial ad request cannot be filled.
- (void)loInterstitialDidFailToLoad:(LOInterstitial *)interstitial {
    [_delegate onInterstitialLoadFail:interstitial];
}

// Called when the interstitial becomes visible to the user.
- (void)loInterstitialImpressionDidTrigger:(LOInterstitial *)interstitial {
    [_delegate onInterstitialDidOpen:interstitial];
}

// Called before the interstitial view controller is presented.
- (void)loInterstitialWillShow:(LOInterstitial *)interstitial {
    
}

// Called after the interstitial view controller is presented.
- (void)loInterstitialDidShow:(LOInterstitial *)interstitial {
    [_delegate onInterstitialDidShow:interstitial];
}

// Called when the user will be directed to an external destination.
- (void)loInterstitialClickDidTrigger:(LOInterstitial *)interstitial {
    [_delegate onInterstitialDidClick:interstitial];
}

// Called when the user is about to leave the application
- (void)loInterstitialWillLeaveApplication:(LOInterstitial *)interstitial {
}


// Called before the interstitial view controller is hidden.
- (void)loInterstitialWillHide:(LOInterstitial *)interstitial {
    
}

// Called after the interstitial view controller is hidden.
- (void)loInterstitialDidHide:(LOInterstitial *)interstitial {
    [_delegate onInterstitialDidClose:interstitial];
}

// Called when the user has earned a reward by watching a rewarded ad.
- (void)loInterstitialWillRewardUser:(LOInterstitial *)interstitial {
    
}

// Called when the interstitial ad fails during display.
- (void)loInterstitialDidFailToDisplay:(LOInterstitial * _Nonnull)interstitial {
    [_delegate onInterstitialShowFail:interstitial];
}

@end
