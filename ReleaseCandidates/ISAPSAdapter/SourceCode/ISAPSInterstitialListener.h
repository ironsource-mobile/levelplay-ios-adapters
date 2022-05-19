//
//  ISAPSInterstitialListener.h
//  ISAPSAdapter
//
//  Created by Sveta Itskovich on 14/12/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@protocol ISAPSISDelegateWrapper <NSObject>

- (void)interstitialDidLoad:(NSString *)placementId;
- (void)interstitial:(NSString *)placementId didFailToLoadAdWithErrorCode:(DTBAdErrorCode)errorCode;
- (void)interstitialDidPresentScreen:(NSString *)placementId;
- (void)interstitialDidDismissScreen:(NSString *)placementId;
- (void)interstitialImpressionFired:(NSString *)placementId;
@end

@interface ISAPSInterstitialListener : NSObject <DTBAdInterstitialDispatcherDelegate>

@property (nonatomic, weak) id<ISAPSISDelegateWrapper> delegate;
@property (nonatomic, strong) NSString * placementID;

- (instancetype)initWithPlacementID:(NSString *)placementID andDelegate:(id<ISAPSISDelegateWrapper>)delegate;

@end

