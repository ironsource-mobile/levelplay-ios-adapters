//
//  ISAdColonyInterstitialListener.h
//  ISAdColonyAdapter
//
//  Created by Roi Eshel on 24/9/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>

@protocol ISAdColonyInterstitialDelegateWrapper <NSObject>
- (void)onInterstitialDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId;
- (void)onInterstitialDidFailToLoad:(NSString *)zoneId withError:(AdColonyAdRequestError *)error;
- (void)onInterstitialDidOpen:(NSString *)zoneId;
- (void)onInterstitialDidClick:(NSString *)zoneId;
- (void)onInterstitialDidClose:(NSString *)zoneId;
@end

@interface ISAdColonyInterstitialListener : NSObject <AdColonyInterstitialDelegate>

@property (nonatomic, strong) NSString *zoneId;
@property (nonatomic, weak) id<ISAdColonyInterstitialDelegateWrapper> delegate;

- (instancetype)initWithZoneId:(NSString *)zoneId andDelegate:(id<ISAdColonyInterstitialDelegateWrapper>)delegate;

@end
