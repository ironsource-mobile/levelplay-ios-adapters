//
//  ISYandexBannerAdDelegate.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISBaseAdapter+Internal.h>

@interface ISYandexBannerAdDelegate : NSObject <YMAAdViewDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate;

@end
