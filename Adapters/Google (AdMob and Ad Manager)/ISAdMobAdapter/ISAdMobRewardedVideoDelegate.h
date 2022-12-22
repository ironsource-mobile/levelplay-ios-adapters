//
//  ISAdMobRewardedVideoDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "IronSource/ISBaseAdapter+Internal.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdMobRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidOpen:(nonnull NSString *)adUnitId;

- (void)onRewardedVideoShowFail:(nonnull NSString *)adUnitId
                      withError:(nonnull NSError *)error;

- (void)onRewardedVideoDidClick:(nonnull NSString *)adUnitId;

- (void)onRewardedVideoDidClose:(nonnull NSString *)adUnitId;



@end

@interface ISAdMobRewardedVideoDelegate : NSObject <GADFullScreenContentDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISAdMobRewardedVideoDelegateWrapper> delegate;


- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISAdMobRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
