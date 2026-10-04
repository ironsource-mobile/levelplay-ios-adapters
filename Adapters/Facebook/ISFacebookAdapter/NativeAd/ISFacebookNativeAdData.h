//
//  ISFacebookNativeAdData.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISAdapterNativeAdData.h>

@interface ISFacebookNativeAdData : ISAdapterNativeAdData

@property (nonatomic, strong) FBNativeAd *nativeAd;

- (instancetype)initWithNativeAd:(FBNativeAd *)nativeAd;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
