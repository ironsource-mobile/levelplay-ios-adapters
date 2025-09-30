//
//  ISInMobiInterstitialDelegate.h
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISInMobiInterstitialDelegateWrapper  <NSObject>

- (void)onInterstitialDidLoad:(IMInterstitial *)interstitial
                  placementId:(NSString *)placementId
                   creativeId:(NSString *)creativeId;

- (void)onInterstitialDidFailToLoad:(IMInterstitial *)interstitial
                              error:(IMRequestStatus *)error
                        placementId:(NSString *)placementId;

- (void)onInterstitialDidOpen:(IMInterstitial *)interstitial
                  placementId:(NSString *)placementId;

- (void)onInterstitialDidFailToShow:(IMInterstitial *)interstitial
                              error:(IMRequestStatus *)error
                        placementId:(NSString *)placementId;

- (void)onInterstitialDidClick:(IMInterstitial *)interstitial
                        params:(NSDictionary *)params
                   placementId:(NSString *)placementId;

- (void)onInterstitialDidClose:(IMInterstitial *)interstitial
                   placementId:(NSString *)placementId;

@end

@interface ISInMobiInterstitialDelegate : NSObject <IMInterstitialDelegate>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISInMobiInterstitialDelegateWrapper> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                           delegate:(id<ISInMobiInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END

