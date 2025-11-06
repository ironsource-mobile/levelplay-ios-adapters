//
//  ISLineRewardedVideoDelegate.m
//  ISLineAdapter
//
//  Copyright © 2025 ironSource Mobile Ltd. All rights reserved.
//

#import "ISLineRewardedVideoDelegate.h"
#import "ISLineRewardedVideoAdapter.h"
#import "ISLineConstants.h"

@implementation ISLineRewardedVideoDelegate

- (instancetype)initWithSlotId:(NSString *)slotId
                       adapter:(ISLineRewardedVideoAdapter *)adapter
                    andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    self = [super init];
    if (self) {
        _slotId = slotId;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)fiveVideoRewardAd:(nonnull FADVideoReward *)ad didFailedToShowAdWithError:(FADErrorCode)errorCode { 
    LogAdapterDelegate_Internal(@"slotId = %@, errorCode = %ld", self.slotId, errorCode);
    NSError *showError = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
    [self.delegate adapterRewardedVideoDidFailToShowWithError:showError];
}

- (void)fiveVideoRewardAdDidReward:(nonnull FADVideoReward *)ad { 
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidReceiveReward];
    [_delegate adapterRewardedVideoDidEnd];
}

- (void)fiveVideoRewardAdDidClick:(nonnull FADVideoReward*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidClick];
}

- (void)fiveVideoRewardAdDidImpression:(nonnull FADVideoReward*)ad{
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

- (void)fiveVideoRewardAdFullScreenDidOpen:(nonnull FADVideoReward*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)fiveVideoRewardAdFullScreenDidClose:(nonnull FADVideoReward*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterRewardedVideoDidClose];
}

- (void)fiveVideoRewardAdDidPlay:(nonnull FADVideoReward*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)fiveVideoRewardAdDidPause:(nonnull FADVideoReward*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)fiveVideoRewardAdDidViewThrough:(nonnull FADVideoReward*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

@end
