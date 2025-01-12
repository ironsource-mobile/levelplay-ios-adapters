//
//  ISVungleInterstitialDelegate.h
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <IronSource/ISBaseAdapter+Internal.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISVungleInterstitialDelegate : NSObject<VungleInterstitialDelegate>

@property (nonatomic, strong) NSString *placementId;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
