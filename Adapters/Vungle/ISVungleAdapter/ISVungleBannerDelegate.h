//
//  ISVungleBannerDelegate.h
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <IronSource/ISBaseAdapter+Internal.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISVungleBannerDelegate : NSObject <VungleBannerDelegate>

@property (nonatomic, strong) NSString *placementId;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                      containerView:(UIView *)containerView
                        andDelegate:(id<ISBannerAdapterDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
