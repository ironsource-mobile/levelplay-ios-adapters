#import "ISOguryInterstitialDelegate.h"

@implementation ISOguryInterstitialDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// The SDK is ready to display the ad provided by the ad server.
- (void)interstitialAdDidLoad:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidLoad];
}

/// The ad failed to load or display.
- (void)interstitialAd:(OguryInterstitialAd *)interstitialAd didFailWithError:(OguryAdError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    if ( error.type == OguryAdErrorTypeLoad )
    {
        [self.delegate adapterInterstitialDidFailToLoadWithError:error];
    }else{
        [self.delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

///  The ad has triggered an impression.
- (void)interstitialAdDidTriggerImpression:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

/// The ad has been clicked by the user.
- (void)interstitialAdDidClick:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClick];
}

/// The ad has been closed by the user.
- (void)interstitialAdDidClose:(OguryInterstitialAd *)interstitial {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterInterstitialDidClose];
}

@end
