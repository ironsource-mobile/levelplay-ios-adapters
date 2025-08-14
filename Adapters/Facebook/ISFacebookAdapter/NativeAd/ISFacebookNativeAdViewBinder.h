//
//  ISFacebookNativeAdViewBinder.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface ISFacebookNativeAdViewBinder : ISAdapterNativeAdViewBinder

- (instancetype)initWithNativeAd:(FBNativeAd *)nativeAd
               adOptionsPosition:(ISAdOptionsPosition)adOptionsPosition
                  viewController:(UIViewController *)viewController;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end



