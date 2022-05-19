//
//  ISInMobiRvListener.h
//  ISInMobiAdapter
//
//  Created by Roni Schwartz on 27/11/2018.
//  Copyright © 2018 supersonic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InMobiSDK/IMInterstitialDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ISInMobiInterstitialListenerDelegate  <NSObject>
- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial placementId:(NSString *)placementId;
- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error placementId:(NSString *)placementId;
- (void)interstitialDidPresent:(IMInterstitial *)interstitial placementId:(NSString *)placementId;
- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error placementId:(NSString *)placementId;
- (void)interstitialDidDismiss:(IMInterstitial *)interstitial placementId:(NSString *)placementId;
- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params placementId:(NSString *)placementId;
@end

@interface ISInMobiInterstitialListener : NSObject <IMInterstitialDelegate>

@property (nonatomic, weak) id<ISInMobiInterstitialListenerDelegate> delegate;
@property (nonatomic, strong) NSString* placementId;

- (instancetype)initWithPlacementId:(NSString *)placementId andDelegate:(id<ISInMobiInterstitialListenerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

