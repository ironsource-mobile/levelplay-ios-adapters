//
//  ISFyberBannerListener.m
//  ISFyberAdapter
//
//  Created by Guy Lis on 27/08/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import "ISFyberBannerListener.h"

@implementation ISFyberBannerListener

- (instancetype)initWithSpotId:(NSString *)spotId
                   andDelegate:(id<ISFyberBannerDelegateWrapper>)delegate {
    self = [super init];
    
    if (self) {
        _spotId = spotId;
        _delegate = delegate;
    }
    
    return self;
}

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return _viewControllerForPresentingModalView;
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    return [_delegate onBannerDidShow:_spotId];
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController
       videoInterruptedWithError:(NSError * _Nonnull)error {
    return [_delegate onBannerDidShowFailed:_spotId
                                  withError:error];
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    return [_delegate onBannerDidClick:_spotId];
}

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
    return [_delegate onBannerBannerWillLeaveApplication:_spotId];
}

@end
