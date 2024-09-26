#import "ISOguryInterstitialDelegate.h"

@implementation ISOguryInterstitialDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                         adState:(AdState)adState
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _adState = adState;
        _delegate = delegate;
    }
    return self;
}

/// The SDK is ready to display the ad provided by the ad server.
- (void)didLoadOguryInterstitialAd:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidLoad];
}

/// The ad failed to load or display.
- (void)didFailOguryInterstitialAdWithError:(OguryError *)error
                                      forAd:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    
    switch (self.adState) {
        case AD_STATE_NONE:
        case AD_STATE_LOAD:
            [self.delegate adapterInterstitialDidFailToLoadWithError:error];
            break;
        case AD_STATE_SHOW:
            [self.delegate adapterInterstitialDidFailToShowWithError:error];
            break;
    }
}

///  The ad has been displayed on the screen.
- (void)didDisplayOguryInterstitialAd:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidShow];
}

/// The ad has triggered an impression.
- (void)didTriggerImpressionOguryInterstitialAd:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidOpen];
}

/// The ad has been clicked by the user.
- (void)didClickOguryInterstitialAd:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClick];
}

/// The ad has been closed by the user.
- (void)didCloseOguryInterstitialAd:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClose];
}

@end
