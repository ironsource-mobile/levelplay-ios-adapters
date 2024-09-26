#import "ISOguryRewardedVideoDelegate.h"

@implementation ISOguryRewardedVideoDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                         adState:(AdState)adState
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
        _adState = adState;
    }
    return self;
}

/// The SDK is ready to display the ad provided by the ad server.
- (void)didLoadOguryOptinVideoAd:(OguryOptinVideoAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

/// The ad failed to load or display.
- (void)didFailOguryOptinVideoAdWithError:(OguryError *)error forAd:(OguryOptinVideoAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    switch (self.adState) {
        case AD_STATE_NONE:
        case AD_STATE_LOAD:
            [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
            [self.delegate adapterRewardedVideoDidFailToLoadWithError:error];
            break;
        case AD_STATE_SHOW:
            [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
            break;
    }
}

///  The ad has been displayed on the screen.
- (void)didDisplayOguryOptinVideoAd:(OguryOptinVideoAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
}

/// The ad has triggered an impression.
- (void)didTriggerImpressionOguryOptinVideoAd:(OguryOptinVideoAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

/// The ad has been clicked by the user.
- (void)didClickOguryOptinVideoAd:(OguryOptinVideoAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClick];
}

/// The ad has been closed by the user.
- (void)didCloseOguryOptinVideoAd:(OguryOptinVideoAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClose];
}

/// The  user must be rewarded, as they has watched the Opt-in Video Ad.
- (void)didRewardOguryOptinVideoAdWithItem:(OGARewardItem *)item forAd:(OguryOptinVideoAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

@end
