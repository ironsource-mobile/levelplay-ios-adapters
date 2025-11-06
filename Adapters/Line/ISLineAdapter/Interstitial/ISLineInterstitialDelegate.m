//
//  ISLineInterstitialDelegate.m
//  ISLineAdapter
//
//  Copyright © 2025 ironSource Mobile Ltd. All rights reserved.
//

#import "ISLineInterstitialDelegate.h"
#import "ISLineConstants.h"
#import "ISLineInterstitialAdapter.h"

@implementation ISLineInterstitialDelegate

- (instancetype)initWithSlotId:(NSString *)slotId
                       adapter:(ISLineInterstitialAdapter *)adapter
                    andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _slotId = slotId;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)fiveInterstitialAd:(nonnull FADInterstitial *)ad didFailedToShowAdWithError:(FADErrorCode)errorCode {
    LogAdapterDelegate_Internal(@"slotId = %@, errorCode = %ld", self.slotId, errorCode);
    NSError *showError = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
    [self.delegate adapterInterstitialDidFailToShowWithError:showError];
}

- (void)fiveInterstitialAdDidClick:(nonnull FADInterstitial*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterInterstitialDidClick];
    
}

- (void)fiveInterstitialAdDidImpression:(nonnull FADInterstitial*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

- (void)fiveInterstitialAdFullScreenDidOpen:(nonnull FADInterstitial*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)fiveInterstitialAdFullScreenDidClose:(nonnull FADInterstitial*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
    [self.delegate adapterInterstitialDidClose];
}

- (void)fiveInterstitialAdDidPlay:(nonnull FADInterstitial*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)fiveInterstitialAdDidPause:(nonnull FADInterstitial*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

- (void)fiveInterstitialAdDidViewThrough:(nonnull FADInterstitial*)ad {
    LogAdapterDelegate_Internal(@"slotId = %@", self.slotId);
}

@end
