//
//  ISFyberInterstitialListener.m
//  ISFyberAdapter
//
//  Created by Guy Lis on 27/08/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import "ISFyberInterstitialListener.h"

@implementation ISFyberInterstitialListener

- (instancetype)initWithSpotId:(NSString *)spotId
                   andDelegate:(id<ISFyberInterstitialDelegateWrapper>)delegate {
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

- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController * _Nullable)unitController {
    return [_delegate onInterstitialDidShow:_spotId];
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController
       videoInterruptedWithError:(NSError * _Nonnull)error {
    return [_delegate onInterstitialShowFailed:_spotId
                                     withError:error];
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    return [_delegate onInterstitialDidClick:_spotId];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    return [_delegate onInterstitialDidClose:_spotId];
}

@end
