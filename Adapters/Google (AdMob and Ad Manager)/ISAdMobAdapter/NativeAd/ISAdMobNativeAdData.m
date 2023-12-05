//
//  ISAdMobNativeAdData.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <ISAdMobNativeAdData.h>

@implementation ISAdMobNativeAdData

- (instancetype)initWithNativeAd:(GADNativeAd *)nativeAd {
    self = [super init];
    if (self) {
        _nativeAd = nativeAd;
    }
    return self;
}

- (NSString *)title {
    LogAdapterDelegate_Internal(@"headline = %@", self.nativeAd.headline);
    return self.nativeAd.headline;
}

- (NSString *)advertiser {
    LogAdapterDelegate_Internal(@"advertiser = %@", self.nativeAd.advertiser);
    return self.nativeAd.advertiser;
}

- (NSString *)body {
    LogAdapterDelegate_Internal(@"body = %@", self.nativeAd.body);
    return self.nativeAd.body;
}

- (NSString *)callToAction {
    LogAdapterDelegate_Internal(@"callToAction = %@", self.nativeAd.callToAction);
    return self.nativeAd.callToAction;
}

- (ISNativeAdDataImage *)icon {
    GADNativeAdImage *icon = self.nativeAd.icon;
    
    if (icon) {
        LogAdapterDelegate_Internal(@"icon url = %@", icon.imageURL);
        return [[ISNativeAdDataImage alloc] initWithImage:icon.image
                                                      url:icon.imageURL];
    }
    
    return nil;
}

@end
