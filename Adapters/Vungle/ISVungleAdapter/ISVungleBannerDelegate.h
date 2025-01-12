//
//  ISVungleBannerDelegate.h
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>
#import <IronSource/ISBaseAdapter+Internal.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISVungleBannerDelegate : NSObject <VungleBannerViewDelegate>

@property (nonatomic, strong) NSString *placementId;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;
@property (nonatomic, assign) BOOL isAdloadSuccess;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISBannerAdapterDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
