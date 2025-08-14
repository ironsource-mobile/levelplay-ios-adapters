//
//  ISFacebookNativeAdDelegate.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <ISFacebookNativeAdAdapter.h>

@interface ISFacebookNativeAdDelegate : NSObject <FBNativeAdDelegate>

+ (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPlacementId:(NSString *)placementId
                  adOptionsPosition:(ISAdOptionsPosition)adOptionsPosition
                     viewController:(UIViewController *)viewController
                           delegate:(id<ISNativeAdAdapterDelegate>)delegate;

@end
