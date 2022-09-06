//
//  ISVungleInterstitialAdapterRouter.m
//  ISVungleAdapter
//
//  Copyright © 2020 ironSource. All rights reserved.
//

#import "ISVungleInterstitialAdapterRouter.h"
#import "ISVungleAdapter.h"

@interface ISVungleInterstitialAdapterRouter()

@property (nonatomic, strong, nullable) NSString *bidPayload;

@end

@implementation ISVungleInterstitialAdapterRouter

- (instancetype)initWithPlacementID:(NSString *)placementID
                      parentAdapter:(ISVungleAdapter *)parentAdapter
                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    if (self = [super init]) {
        _placementID = placementID;
        _parentAdapter = parentAdapter;
        _delegate = delegate;
        _bidPayload = nil;
    }

    return self;
}

- (void)loadInterstitial {
    self.interstitialAd = [[VungleInterstitial alloc] initWithPlacementId:self.placementID];
    self.interstitialAd.delegate = self;
    
    if ([self.interstitialAd canPlayAd]) {
        LogInternal_Internal(@"Interstitial ad: %@ is loaded", self.placementID);
        [self.delegate adapterInterstitialDidLoad];
        return;
    }
 
    [self.interstitialAd load:self.bidPayload];
}

- (void)playInterstitialAdWithViewController:(UIViewController *)viewController {
    [self.interstitialAd presentWith:viewController];
}

- (void)setBidPayload:(NSString * _Nullable)bidPayload {
    self.bidPayload = bidPayload;
}

- (void)interstitialInitSuccess {
    [self.delegate adapterInterstitialInitSuccess];
}

- (void)interstitialInitFailed:(NSError *)error;{
    [self.delegate adapterInterstitialInitFailedWithError:error];
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
    if (![interstitial canPlayAd]) {
        // When Interstitial is loaded the canPlayAd should also return YES
        // If for some reason that is not the case we can also catch it on the Show method
        LogAdapterDelegate_Internal(@"Vungle Ad is loaded but not ready to be shown");
    }

    [self.delegate adapterInterstitialDidLoad];
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial * _Nonnull)interstitial withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementID = %@, error = %@", interstitial.placementId, error);
    [self.delegate adapterInterstitialDidFailToLoadWithError:error];
}

- (void)interstitialAdDidTrackImpression:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial * _Nonnull)interstitial withError:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementID = %@, error = %@", interstitial.placementId, error);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

- (void)interstitialAdDidClose:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
    [self.delegate adapterInterstitialDidClose];
}

- (void)interstitialAdDidClick:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
    [self.delegate adapterInterstitialDidClick];
}

- (void)interstitialAdWillPresent:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
}

- (void)interstitialAdDidPresent:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
}

- (void)interstitialAdWillClose:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
}

- (void)interstitialAdWillLeaveApplication:(VungleInterstitial * _Nonnull)interstitial {
    LogAdapterDelegate_Internal(@"placementID = %@", interstitial.placementId);
}

@end
