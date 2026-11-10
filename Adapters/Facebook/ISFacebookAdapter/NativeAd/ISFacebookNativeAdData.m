//
//  ISFacebookNativeAdData.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISFacebookNativeAdData.h"
#import "ISFacebookConstants.h"
#import <IronSource/ISNativeAdDataImage.h>
#import <IronSource/ISLog.h>

@implementation ISFacebookNativeAdData

- (instancetype)initWithNativeAd:(FBNativeAd *)nativeAd {
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
    LogAdapterDelegate_Internal(logAdvertiser, self.nativeAd.advertiserName);
    return self.nativeAd.advertiserName;
}

- (NSString *)body {
    LogAdapterDelegate_Internal(logBody, self.nativeAd.bodyText);
    return self.nativeAd.bodyText;
}

- (NSString *)callToAction {
    LogAdapterDelegate_Internal(logCallToAction, self.nativeAd.callToAction);
    return self.nativeAd.callToAction;
}

- (ISNativeAdDataImage *)icon {
    UIImage *icon = self.nativeAd.iconImage;

    if (icon) {
        LogAdapterDelegate_Internal(logCallbackEmpty);
        return [[ISNativeAdDataImage alloc] initWithImage:icon
                                                      url:nil];
    }

    return nil;
}

@end
