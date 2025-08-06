//
//  ISAdMobNativeBannerTemplate.h
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>

@interface ISAdMobNativeBannerTemplate : NSObject

@property(assign, nonatomic) NSString* nibName;
@property(assign, nonatomic) BOOL hideCallToAction;
@property(assign, nonatomic) BOOL hideVideoContent;
@property(nonatomic) GADAdChoicesPosition adChoicesPosition;
@property(nonatomic) GADMediaAspectRatio mediaAspectRatio;
@property(assign, nonatomic) CGRect frame;

- (instancetype)initWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                      sizeDescription:(NSString *)sizeDescription;
@end
