//
//  ISFacebookBannerDelegate.h
//  ISFacebookAdapter
//
//  Created by Hadar Pur on 01/08/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISFacebookBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull NSString *)placementID
             bannerView:(FBAdView *)bannerView;

- (void)onBannerDidFailToLoad:(nonnull NSString *)placementID
                    withError:(nullable NSError *)error;

- (void)onBannerDidShow:(nonnull NSString *)placementID;

- (void)onBannerDidClick:(nonnull NSString *)placementID;

@end

@interface ISFacebookBannerDelegate : NSObject <FBAdViewDelegate>

@property (nonatomic, strong) NSString* placementID;
@property (nonatomic, weak) id<ISFacebookBannerDelegateWrapper> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID
                        andDelegate:(id<ISFacebookBannerDelegateWrapper>)delegate;

@end


NS_ASSUME_NONNULL_END

