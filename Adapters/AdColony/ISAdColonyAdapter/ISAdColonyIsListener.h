//
//  ISAdColonyIsListener.h
//  ISAdColonyAdapter
//
//  Created by Roi Eshel on 24/9/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>

@protocol ISAdColonyISDelegateWrapper <NSObject>
- (void)interstitialDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId;
- (void)interstitialDidFailToLoadForZoneId:(NSString *)zoneId withError:(AdColonyAdRequestError *)error;
- (void)interstitialWillOpenForZoneId:(NSString *)zoneId;
- (void)interstitialDidReceiveClickForZoneId:(NSString *)zoneId;
- (void)interstitialDidCloseForZoneId:(NSString *)zoneId;
- (void)interstitialExpiredForZoneId:(NSString *)zoneId;
@end

@interface ISAdColonyIsListener : NSObject <AdColonyInterstitialDelegate>

@property (nonatomic, strong) NSString *zoneId;
@property (nonatomic, weak) id<ISAdColonyISDelegateWrapper> delegate;

- (instancetype)initWithZoneId:(NSString *)zoneId andDelegate:(id<ISAdColonyISDelegateWrapper>)delegate;

@end
