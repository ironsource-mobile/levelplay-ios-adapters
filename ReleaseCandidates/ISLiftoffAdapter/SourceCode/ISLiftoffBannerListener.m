//
//  ISLiftoffBannerListener.m
//  ISLiftoffAdapter
//
//  Created by Roi Eshel on 14/09/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISLiftoffBannerListener.h"

@implementation ISLiftoffBannerListener

- (instancetype)initWithDelegate:(id<ISLiftoffBannerDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

// Called when the banner ad request is successfully filled. The view argument
// is the banner's UIView.
- (void)loBannerDidLoad:(LOBanner *)banner view:(UIView *)view {
    [_delegate onBannerLoadSuccess:banner withView:view];
}

// Called when the banner ad request cannot be filled.
- (void)loBannerDidFailToLoad:(LOBanner *)banner {
    [_delegate onBannerLoadFail:banner];
}

// Called when the banner becomes visible to the user.
- (void)loBannerImpressionDidTrigger:(LOBanner *)banner {
    [_delegate onBannerDidShow:banner];
}

// Called when the user will be directed to an external destination.
- (void)loBannerClickDidTrigger:(LOBanner *)banner {
    [_delegate onBannerDidClick:banner];
    
}

// Implementing this by returning a root view controller allows banners to
// present a StoreKit modal for app installs, which may improve conversion rates
// and your eCPM.
- (UIViewController *)loBannerViewControllerForPresentingModalView:(LOBanner *)banner {
    return nil;
}

// Called when a modal view controller will be displayed after a user click.
- (void)loBannerModalWillShow:(LOBanner *)banner {
    [_delegate onBannerWillPresentScreen:banner];
}

// Called when a modal view controller is displayed after a user click.
- (void)loBannerModalDidShow:(LOBanner *)banner {}

// Called when a modal view controller will be dismissed.
- (void)loBannerModalWillHide:(LOBanner *)banner {}

// Called when a modal view controller is dismissed.
- (void)loBannerModalDidHide:(LOBanner *)banner {
    [_delegate onBannerDidDismissScreen:banner];
}

// Called when the user will be directed to an external destination.
- (void)loBannerWillLeaveApplication:(LOBanner *)banner {
    [_delegate onBannerBannerWillLeaveApplication:banner];
}

@end
