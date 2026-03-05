//
//  ISYandexBannerDelegate.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>

@protocol ISBannerAdDelegate;

@interface ISYandexBannerDelegate : NSObject <YMAAdViewDelegate>

@property (nonatomic, strong) NSString *adUnitId;
@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdDelegate>)delegate;

@end
