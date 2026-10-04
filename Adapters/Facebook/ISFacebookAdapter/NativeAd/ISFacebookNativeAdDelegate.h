//
//  ISFacebookNativeAdDelegate.h
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISAdOptionsPosition.h>

@protocol ISNativeAdDelegate;

@interface ISFacebookNativeAdDelegate : NSObject <FBNativeAdDelegate>

@property (nonatomic, assign) ISAdOptionsPosition        adOptionsPosition;
@property (nonatomic, strong) UIViewController           *viewController;
@property (nonatomic, weak)   id<ISNativeAdDelegate>     delegate;

- (instancetype)initWithAdOptionsPosition:(ISAdOptionsPosition)adOptionsPosition
                          viewController:(UIViewController *)viewController
                                delegate:(id<ISNativeAdDelegate>)delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@end
