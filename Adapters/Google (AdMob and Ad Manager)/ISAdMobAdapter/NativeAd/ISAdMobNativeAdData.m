//
//  ISAdMobNativeAdData.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAdMobNativeAdData.h"
#import "ISAdMobConstants.h"
#import <IronSource/ISNativeAdDataImage.h>
#import <IronSource/ISLog.h>

@implementation ISAdMobNativeAdData

- (instancetype)initWithNativeAd:(GADNativeAd *)nativeAd {
    self = [super init];
    if (self) {
        _nativeAd = nativeAd;
    }
    return self;
}

- (NSString *)title {
    LogAdapterDelegate_Internal(logHeadline, self.nativeAd.headline);
    return self.nativeAd.headline;
}

- (NSString *)advertiser {
    LogAdapterDelegate_Internal(logAdvertiser, self.nativeAd.advertiser);
    return self.nativeAd.advertiser;
}

- (NSString *)body {
    LogAdapterDelegate_Internal(logBody, self.nativeAd.body);
    return self.nativeAd.body;
}

- (NSString *)callToAction {
    LogAdapterDelegate_Internal(logCallToAction, self.nativeAd.callToAction);
    return self.nativeAd.callToAction;
}

- (ISNativeAdDataImage *)icon {
    GADNativeAdImage *icon = self.nativeAd.icon;

    if (icon) {
        LogAdapterDelegate_Internal(logIcon, icon.imageURL);
        return [[ISNativeAdDataImage alloc] initWithImage:icon.image
                                                      url:icon.imageURL];
    }

    return nil;
}

@end
