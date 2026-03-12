//
//  ISUADSRewardedShowDelegate.h
//  ISUnityAdsAdapter
//
//   Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import <ISUnityAdsAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISUADSRewardedShowDelegate : NSObject <UADSRewardedShowDelegate>

- (instancetype _Nonnull)initWithPlacementId:(NSString * _Nonnull)placementId
                                    delegate:(id<ISRewardedVideoAdapterDelegate> _Nonnull)delegate;
@end

NS_ASSUME_NONNULL_END
