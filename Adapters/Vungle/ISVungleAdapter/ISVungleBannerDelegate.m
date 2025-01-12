//
//  ISVungleBannerDelegate.m
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISVungleBannerDelegate.h"
#import "ISVungleConstant.h"

@implementation ISVungleBannerDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    
    if (self) {
        _placementId = placementId;
        _delegate = delegate;
        _isAdloadSuccess = NO;
    }
    
    return self;
}

#pragma mark - VungleBannerView Delegate

- (void)bannerAdDidLoad:(VungleBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    self.isAdloadSuccess = YES;
    [self.delegate adapterBannerDidLoad:bannerView];
}

// This callback is called both for banner load failures and banner show failures
- (void)bannerAdDidFail:(VungleBannerView * _Nonnull)bannerView
              withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@ error = %@", self.placementId, error);
    NSInteger errorCode = (error.code == VungleErrorAdNoFill) ? ERROR_BN_LOAD_NO_FILL : error.code;
    NSError *bannerError = [NSError errorWithDomain:kAdapterName
                                               code:errorCode
                                           userInfo:@{NSLocalizedDescriptionKey:error.description}];

    if (!self.isAdloadSuccess) {
        [self.delegate adapterBannerDidFailToLoadWithError:bannerError];
    } else {
        [self.delegate adapterBannerDidFailToShowWithError:bannerError];
    }
}

- (void)bannerAdDidTrackImpression:(VungleBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidShow];
}

- (void)bannerAdDidClick:(VungleBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidClick];
}

- (void)bannerAdWillLeaveApplication:(VungleBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerWillLeaveApplication];
}

@end
