//
//  ISMolocoBannerDelegate.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

@protocol ISBannerAdDelegate;

@interface ISMolocoBannerDelegate : NSObject <MolocoBannerDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate>     delegate;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate;

@end
