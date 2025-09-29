//
//  ISChartboostInterstitialDelegate.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <ChartboostSDK/ChartboostSDK.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISChartboostInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidLoad:(nonnull NSString *)locationId
               withCreativeId:(nonnull NSString *)creativeId;

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)locationId
                          withError:(nonnull CHBCacheError *)error;

- (void)onInterstitialShowFail:(nonnull NSString *)locationId
                     withError:(nonnull CHBShowError *)error;

- (void)onInterstitialDidClick:(nonnull NSString *)locationId
                     withError:(nullable CHBClickError *)error;


- (void)onInterstitialDidClose:(nonnull NSString *)locationId;

- (void)onInterstitialDidExpire:(nonnull NSString *)locationId;

- (void)onInterstitialDidRecordImpression:(nonnull NSString *)locationId
                               withCreativeId:(nonnull NSString *)creativeId;

@end

@interface ISChartboostInterstitialDelegate : NSObject <CHBInterstitialDelegate>

@property (nonatomic, strong) NSString *locationId;
@property (nonatomic, weak)   id<ISChartboostInterstitialDelegateWrapper> delegate;

- (instancetype)initWithLocationId:(NSString *)locationId
                       andDelegate:(id<ISChartboostInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
