//
//  ISAdMobNativeAdDelegate.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ISAdMobNativeAdAdapter.h>

@interface ISAdMobNativeAdDelegate : NSObject <GADNativeAdLoaderDelegate, GADAdLoaderDelegate, GADNativeAdDelegate>

@property (nonatomic, strong)   NSString                       *adUnitId;
@property (nonatomic, strong)   UIViewController               *viewController;
@property (nonatomic, weak)     id<ISNativeAdAdapterDelegate>  delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                  viewController:(UIViewController *)viewController
                     andDelegate:(id<ISNativeAdAdapterDelegate>)delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
