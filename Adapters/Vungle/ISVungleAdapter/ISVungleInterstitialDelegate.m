//
//  ISVungleInterstitialDelegate.m
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISVungleInterstitialDelegate.h"
#import "ISVungleConstant.h"

@implementation ISVungleInterstitialDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
    }
    return self;
}


#pragma mark - Interstitial Delegate

- (void)interstitialAdDidLoad:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidLoad];
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial * _Nonnull)interstitial
                          withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);
    
    NSInteger errorCode = (error.code == VungleErrorAdNoFill) ? ERROR_IS_LOAD_NO_FILL : error.code;
    NSError *interstitialError = [NSError errorWithDomain:kAdapterName
                                                     code:errorCode
                                                 userInfo:@{NSLocalizedDescriptionKey:error.description}];

    [self.delegate adapterInterstitialDidFailToLoadWithError:interstitialError];
}

- (void)interstitialAdDidTrackImpression:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial * _Nonnull)interstitial
                             withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error.description);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

- (void)interstitialAdDidClick:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidClick];
}

- (void)interstitialAdDidClose:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterInterstitialDidClose];
}

@end
