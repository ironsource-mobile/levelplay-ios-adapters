//
//  ISAPSBannerListener.h
//  ISAPSAdapter
//
//  Created by Sveta Itskovich on 14/12/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@protocol ISAPSBNSDelegateWrapper <NSObject>
- (void)bannerAdDidLoad:(NSString *)placementId withBanner:(UIView *)adView;
- (void)bannerAdFailedToLoad:(NSString *)placementId errorCode:(NSInteger)errorCode;
- (void)bannerWillLeaveApplication:(NSString *)placementId;
- (void)bannerImpressionFired:(NSString *)placementId;


@end

@interface ISAPSBannerListener : NSObject <DTBAdBannerDispatcherDelegate>

@property (nonatomic, weak) id<ISAPSBNSDelegateWrapper> delegate;
@property (nonatomic, strong) NSString *placementID;

-(instancetype)initWithPlacementID:(NSString *)placementID andDelegate:(id<ISAPSBNSDelegateWrapper>)delegate;

@end



