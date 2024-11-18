#import "ISOguryBannerDelegate.h"
#import "ISOguryBannerAdapter.h"

@implementation ISOguryBannerDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                andBannerAdapter:(ISOguryBannerAdapter *)adapter
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

/// The SDK is ready to display the ad provided by the ad server.
- (void)bannerAdViewDidLoad:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidLoad:bannerAd];
}

///  The ad failed to load or display.
- (void)bannerAdView:(OguryBannerAdView *)bannerAd didFailWithError:(OguryAdError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    [self.delegate adapterBannerDidFailToLoadWithError:error];
}

/// The ad has triggered an impression.
- (void)bannerAdViewDidTriggerImpression:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidShow];
}

/// The ad has been clicked by the user.
- (void)bannerAdViewDidClick:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidClick];

}

/// The ad has been closed by the user.
- (void)bannerAdViewDidClose:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    //bannerAdViewDidClose must be called before the OguryBannerAdView is removed
    [self.adapter removeBannerAd];
    self.adapter = nil;
}

@end
