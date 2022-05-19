//
//  ISAdColonyRvListener.h
//  ISAdColonyAdapter
//
//  Created by Roi Eshel on 24/9/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>

@protocol ISAdColonyRVDelegateWrapper <NSObject>
- (void)rvDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId;
- (void)rvDidFailToLoadForZoneId:(NSString *)zoneId withError:(AdColonyAdRequestError *)error;
- (void)rvWillOpenForZoneId:(NSString *)zoneId;
- (void)rvDidReceiveClickForZoneId:(NSString *)zoneId;
- (void)rvDidCloseForZoneId:(NSString *)zoneId;
- (void)rvExpiredForZoneId:(NSString *)zoneId;
@end

@interface ISAdColonyRvListener : NSObject <AdColonyInterstitialDelegate>

@property (nonatomic, strong) NSString *zoneId;
@property (nonatomic, weak) id<ISAdColonyRVDelegateWrapper> delegate;

- (instancetype)initWithZoneId:(NSString *)zoneId andDelegate:(id<ISAdColonyRVDelegateWrapper>)delegate;

@end
