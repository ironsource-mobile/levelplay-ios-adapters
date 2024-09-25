#import "ISBigoInterstitialDelegate.h"

@implementation ISBigoInterstitialDelegate

- (instancetype)initWithSlotId:(NSString *)slotId
                    andInterstitialAdapter:(ISBigoInterstitialAdapter *)adapter
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _slotId = slotId;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)onInterstitialAdLoaded:(nonnull BigoInterstitialAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [_adapter setInterstitialAd:ad];
    [_delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialAdLoadError:(BigoAdError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@ with error = %@", self.slotId, error);
    NSError *loadError = [ISError createError:error.errorCode
                                    withMessage:error.errorMsg];
    [_delegate adapterInterstitialDidFailToLoadWithError:loadError];
}

- (void)onAd:(BigoAd *)ad error:(BigoAdError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@ with error = %@", self.slotId, error);
    NSError *showError = [ISError createError:error.errorCode
                                  withMessage:error.errorMsg];
    
    [_delegate adapterInterstitialDidFailToShowWithError:showError];
}

- (void)onAdImpression:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [_delegate adapterInterstitialDidOpen];
    [_delegate adapterInterstitialDidShow];
}

- (void)onAdClicked:(BigoAd *)ad {
    [_delegate adapterInterstitialDidClick];
}

- (void)onAdOpened:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)onAdClosed:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [_delegate adapterInterstitialDidClose];
}

@end
