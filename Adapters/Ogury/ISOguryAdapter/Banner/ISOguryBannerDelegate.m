#import "ISOguryBannerDelegate.h"
#import "ISOguryBannerAdapter.h"

@implementation ISOguryBannerDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// The SDK is ready to display the ad provided by the ad server.
- (void)didLoadOguryBannerAd:(OguryBannerAd *)banner {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidLoad:banner];
}

///  The ad failed to load or display.
- (void)didFailOguryBannerAdWithError:(OguryError *)error forAd:(OguryBannerAd *)banner {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterBannerDidFailToLoadWithError:error];
}

///  The ad has been displayed on the screen.
- (void)didDisplayOguryBannerAd:(OguryBannerAd *)banner {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    //ignore
}

/// The ad has triggered an impression.
- (void)didTriggerImpressionOguryBannerAd:(OguryBannerAd *)banner {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidShow];
}

/// The ad has been clicked by the user.
- (void)didClickOguryBannerAd:(OguryBannerAd *)banner {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidClick];

}

/// The ad has been closed by the user.
- (void)didCloseOguryBannerAd:(OguryBannerAd *)banner {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

@end
