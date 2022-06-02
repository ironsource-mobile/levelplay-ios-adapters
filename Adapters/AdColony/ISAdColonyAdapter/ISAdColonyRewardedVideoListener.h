//
//  ISAdColonyRewardedVideoListener.h
//  ISAdColonyAdapter
//
//  Created by Roi Eshel on 24/9/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>

@protocol ISAdColonyRewardedVideoDelegateWrapper <NSObject>
- (void)onRewardedVideoDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId;
- (void)onRewardedVideoDidFailToLoad:(NSString *)zoneId withError:(AdColonyAdRequestError *)error;
- (void)onRewardedVideoDidOpen:(NSString *)zoneId;
- (void)onRewardedVideoDidClick:(NSString *)zoneId;
- (void)onRewardedVideoExpired:(NSString *)zoneId;
- (void)onRewardedVideoDidClose:(NSString *)zoneId;
@end

@interface ISAdColonyRewardedVideoListener : NSObject <AdColonyInterstitialDelegate>

@property (nonatomic, strong) NSString *zoneId;
@property (nonatomic, weak) id<ISAdColonyRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithZoneId:(NSString *)zoneId andDelegate:(id<ISAdColonyRewardedVideoDelegateWrapper>)delegate;

@end
