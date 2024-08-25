//
//  ISFacebookNativeAdData.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import "ISFacebookNativeAdData.h"

@implementation ISFacebookNativeAdData

- (instancetype)initWithNativeAd:(FBNativeAd *)nativeAd {
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
    LogAdapterDelegate_Internal(@"advertiser = %@", self.nativeAd.advertiserName);
    return self.nativeAd.advertiserName;
}

- (NSString *)body {
    LogAdapterDelegate_Internal(@"body = %@", self.nativeAd.bodyText);
    return self.nativeAd.bodyText;
}

- (NSString *)callToAction {
    LogAdapterDelegate_Internal(@"callToAction = %@", self.nativeAd.callToAction);
    return self.nativeAd.callToAction;
}

- (ISNativeAdDataImage *)icon {
    UIImage *icon = self.nativeAd.iconImage;

    if (icon) {
        LogAdapterDelegate_Internal(@"");
        return [[ISNativeAdDataImage alloc] initWithImage:icon
                                                      url:nil];
    }
    
    return nil;
}

@end
