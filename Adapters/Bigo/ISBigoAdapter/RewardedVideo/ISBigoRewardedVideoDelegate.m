#import "ISBigoRewardedVideoDelegate.h"

@implementation ISBigoRewardedVideoDelegate

- (instancetype)initWithSlotId:(NSString *)slotId
              andRewardedAdapter:(ISBigoRewardedVideoAdapter *)adapter
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _slotId = slotId;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)onRewardVideoAdLoaded:(nonnull BigoRewardVideoAd *)ad { 
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.adapter setRewardedAd:ad];
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardVideoAdLoadError:(BigoAdError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@ with error = %@", self.slotId, error);
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];

    NSError *loadError = [ISError createError:error.errorCode
                                    withMessage:error.errorMsg];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:loadError];
    
}


- (void)onAd:(BigoAd *)ad error:(BigoAdError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@ with error = %@", self.slotId, error);
    NSError *showError = [ISError createError:error.errorCode
                                  withMessage:error.errorMsg];
    [self.delegate adapterRewardedVideoDidFailToShowWithError:showError];
}

- (void)onAdImpression:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

- (void)onAdClicked:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidClick];
}

- (void)onAdOpened:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)onAdClosed:(BigoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidClose];
}

- (void)onAdRewarded:(BigoRewardVideoAd *)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

@end
