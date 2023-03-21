//
//  ISPangleBannerDelegate.m
//  ISPangleAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISPangleBannerDelegate.h>

@implementation ISPangleBannerDelegate

- (instancetype)initWithSlotId:(NSString *)slotId
                   andDelegate:(id<ISPangleBannerDelegateWrapper>)delegate {
    
    self = [self init];
    
    if (self) {
        _slotId = slotId;
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark PAGBannerAdDelegate Delegates

/// This method is invoked when the ad is displayed, covering the device's screen.
- (void)adDidShow:(id<PAGAdProtocol>)ad {
    [_delegate onBannerDidShow:_slotId];
}

/// This method is invoked when the ad is clicked by the user.
- (void)adDidClick:(id<PAGAdProtocol>)ad {
    [_delegate onBannerDidClick:_slotId];
}

@end
