#import "ISBigoBannerDelegate.h"
#import "ISBigoBannerAdapter.h"

@implementation ISBigoBannerDelegate

- (instancetype)initWithSlotId:(NSString *)adUnitId
                andBannerAdapter:(ISBigoBannerAdapter *)adapter
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _slotId = adUnitId;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)onBannerAdLoaded:(nonnull BigoBannerAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    
    [self.adapter setBannerAd:ad];
    [self.delegate adapterBannerDidLoad:ad.adView];
}

- (void)onBannerAdLoadError:(BigoAdError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@ with error = %@", self.slotId, error);
    NSError *loadError = [ISError createError:error.errorCode
                                    withMessage:error.errorMsg];
    [self.delegate adapterBannerDidFailToLoadWithError:loadError];
}


- (void)onAd:(BigoAd *)ad error:(BigoAdError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@ with error = %@", self.slotId, error);
    NSError *loadError = [ISError createError:error.errorCode
                                    withMessage:error.errorMsg];
    [self.delegate adapterBannerDidFailToLoadWithError:loadError];
}

- (void)onAdImpression:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterBannerDidShow];
}

- (void)onAdClicked:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterBannerDidClick];
}


@end
