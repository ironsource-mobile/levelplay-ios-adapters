//
//  ISPangleInterstitialDelegate.m
//  ISPangleAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISPangleInterstitialDelegate.h>

@implementation ISPangleInterstitialDelegate

- (instancetype)initWithSlotId:(NSString *)slotId
                   andDelegate:(id<ISPangleInterstitialDelegateWrapper>)delegate {
    
    self = [self init];
    
    if (self) {
        _slotId = slotId;
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark PAGInterstitialAdDelegate Delegates


/// This method is invoked when the ad is displayed, covering the device's screen.
- (void)adDidShow:(id<PAGAdProtocol>)ad {
    [_delegate onInterstitialDidOpen:_slotId];
}

/// This method is invoked when the ad is clicked by the user.
- (void)adDidClick:(id<PAGAdProtocol>)ad {
    [_delegate onInterstitialDidClick:_slotId];
}

/// This method is invoked when the ad disappears.
- (void)adDidDismiss:(id<PAGAdProtocol>)ad {
    [_delegate onInterstitialDidClose:_slotId];
}

@end
