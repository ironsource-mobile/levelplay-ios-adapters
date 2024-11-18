#import "ISOguryRewardedVideoDelegate.h"

@implementation ISOguryRewardedVideoDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// The SDK is ready to display the ad provided by the ad server.
- (void)rewardedAdDidLoad:(OguryRewardedAd *)optinVideo {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

/// The ad failed to load or display.
- (void)rewardedAd:(OguryRewardedAd *)rewardedAd didFailWithError:(OguryAdError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", self.adUnitId, error);
    if ( error.type == OguryAdErrorTypeLoad ){
        [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
        [self.delegate adapterRewardedVideoDidFailToLoadWithError:error];
    }else{
        [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

/// The ad has triggered an impression.
- (void)rewardedAdDidTriggerImpression:(OguryRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

/// The ad has been clicked by the user.
- (void)rewardedAdDidClick:(OguryRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClick];
}

/// The ad has been closed by the user.
- (void)rewardedAdDidClose:(OguryRewardedAd *)rewardedAd {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidClose];
}

/// The  user must be rewarded, as they has watched the Opt-in Video Ad.
- (void)rewardedAd:(OguryRewardedAd *)rewardedAd didReceiveReward:(OguryReward *)reward {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

@end
