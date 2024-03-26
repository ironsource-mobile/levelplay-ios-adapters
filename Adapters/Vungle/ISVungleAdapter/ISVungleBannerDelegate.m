//
//  ISVungleBannerDelegate.m
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISVungleBannerDelegate.h"
#import "ISVungleConstant.h"

@implementation ISVungleBannerDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                      containerView:(UIView *)containerView
                        andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _containerView = containerView;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Banner Delegate

- (void)bannerAdDidLoad:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);

    [self.delegate adapterBannerDidLoad:self.containerView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [banner presentOn:self.containerView];
    });
}

- (void)bannerAdDidFailToLoad:(VungleBanner * _Nonnull)banner
                    withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@ error = %@", self.placementId, error);
    
    NSInteger errorCode = (error.code == kVungleNoFillErrorCode) ? ERROR_BN_LOAD_NO_FILL : error.code;
    NSError *bannerError = [NSError errorWithDomain:kAdapterName
                                               code:errorCode
                                           userInfo:@{NSLocalizedDescriptionKey:error.description}];

    [self.delegate adapterBannerDidFailToLoadWithError:bannerError];
}

- (void)bannerAdDidTrackImpression:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidShow];
}

- (void)bannerAdDidClick:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerDidClick];
}

- (void)bannerAdWillLeaveApplication:(VungleBanner * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterBannerWillLeaveApplication];
}

@end
