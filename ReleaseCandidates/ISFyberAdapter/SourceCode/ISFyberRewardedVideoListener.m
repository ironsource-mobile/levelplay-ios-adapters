//
//  ISFyberRewardedVideoListener.m
//  ISFyberAdapter
//
//  Created by Guy Lis on 27/08/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import "ISFyberRewardedVideoListener.h"

@implementation ISFyberRewardedVideoListener

- (instancetype)initWithSpotId:(NSString *)spotId
                   andDelegate:(id<ISFyberRewardedVideoDelegateWrapper>)delegate {
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
    return [_delegate onRewardedVideoDidShow:_spotId];
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController
       videoInterruptedWithError:(NSError * _Nonnull)error {
    return [_delegate onRewardedVideoShowFailed:_spotId
                                      withError:error];
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    return [_delegate onRewardedVideoDidClick:_spotId];
}

- (void)IAAdDidReward:(IAUnitController * _Nullable)unitController {
    return [_delegate onRewardedVideoDidReceiveReward:_spotId];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    return [_delegate onRewardedVideoDidClose:_spotId];
}

@end
