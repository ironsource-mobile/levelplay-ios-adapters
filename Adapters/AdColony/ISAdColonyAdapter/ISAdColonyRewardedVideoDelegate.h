//
//  ISAdColonyRewardedVideoDelegate.h
//  ISAdColonyAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISAdColonyRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidLoad:(nonnull AdColonyInterstitial *)ad
                     forZoneId:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)zoneId
                           withError:(nonnull AdColonyAdRequestError *)error;

- (void)onRewardedVideoDidOpen:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidClick:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidReceiveRewardCallback:(nonnull NSString *)zoneId
                                withRewardGrant:(BOOL) withRewardGrant;

- (void)onRewardedVideoExpired:(nonnull NSString *)zoneId;

- (void)onRewardedVideoDidClose:(nonnull NSString *)zoneId;

@end

@interface ISAdColonyRewardedVideoDelegate : NSObject <AdColonyInterstitialDelegate>

@property (nonatomic, strong) NSString *zoneId;
@property (nonatomic, weak) id<ISAdColonyRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithZoneId:(NSString *)zoneId
                   andDelegate:(id<ISAdColonyRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
