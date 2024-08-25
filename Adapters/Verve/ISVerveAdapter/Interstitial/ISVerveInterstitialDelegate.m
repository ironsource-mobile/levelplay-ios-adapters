//
//  ISVerveInterstitialDelegate.m
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISVerveInterstitialDelegate.h"

@implementation ISVerveInterstitialDelegate

- (instancetype)initWithZoneId:(NSString *)zoneId
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _zoneId = zoneId;
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad successfully loaded and ready to be displayed.
- (void)interstitialDidLoad {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterInterstitialDidLoad];
}

/// calls this method when ad was not loaded for some reasons
/// @param error the reason of failing loading
- (void)interstitialDidFailWithError:(NSError * _Null_unspecified)error {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    NSError *smashError = error.code == HyBidErrorCodeNoFill ? [ISError createError:ERROR_IS_LOAD_NO_FILL
                                                                                  withMessage:@"Verve no fill"] : error;
    
    [self.delegate adapterInterstitialDidFailToLoadWithError:smashError];
}

/// calls this method when user clicked on the ad
- (void)interstitialDidTrackClick {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterInterstitialDidClick];
}

/// calls this method when ad was dismissed by user action using the close button
- (void)interstitialDidDismiss {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterInterstitialDidClose];
}

/// calls this method when ad has been presented to the user
- (void)interstitialDidTrackImpression {
    LogAdapterDelegate_Internal(@"zoneId = %@", self.zoneId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
    [self.delegate adapterInterstitialDidBecomeVisible];
}

@end
