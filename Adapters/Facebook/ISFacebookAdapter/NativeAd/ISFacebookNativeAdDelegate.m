//
//  ISFacebookNativeAdDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import "ISFacebookNativeAdDelegate.h"
#import "ISFacebookNativeAdData.h"
#import "ISFacebookNativeAdViewBinder.h"
#import "ISFacebookConstants.h"

@interface ISFacebookNativeAdDelegate()

@property (nonatomic, strong) NSString                      *placementId;
@property (nonatomic, strong) UIViewController              *viewController;

@property (nonatomic, assign) ISAdOptionsPosition           adOptionsPosition;
@property (nonatomic, weak) id<ISNativeAdAdapterDelegate>   delegate;

@end

@implementation ISFacebookNativeAdDelegate

- (instancetype)initWithPlacementId:(NSString *)placementId
                  adOptionsPosition:(ISAdOptionsPosition)adOptionsPosition
                     viewController:(UIViewController *)viewController
                           delegate:(id<ISNativeAdAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _adOptionsPosition = adOptionsPosition;
        _viewController = viewController;
        _delegate = delegate;
    }
    return self;
}

/**
 Sent when a FBNativeAd has been successfully loaded.
 @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    
    [nativeAd unregisterView];
    
    ISAdapterNativeAdData *adData = [[ISFacebookNativeAdData alloc] initWithNativeAd:nativeAd];
    ISFacebookNativeAdViewBinder *binder = [[ISFacebookNativeAdViewBinder alloc] initWithNativeAd:nativeAd
                                                                                adOptionsPosition:self.adOptionsPosition
                                                                                   viewController:self.viewController];

    [self.delegate adapterNativeAdDidLoadWithAdData:adData
                                       adViewBinder:binder];
}

/**
 Sent when a FBNativeAd has succesfully downloaded all media
 */
- (void)nativeAdDidDownloadMedia:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
}

/**
 Sent when a FBNativeAd is failed to load.
 @param nativeAd A FBNativeAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)nativeAd:(FBNativeAd *)nativeAd
didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", self.placementId, error);
    
    NSInteger errorCode;
    NSString *errorReason;

    if (error) {
        errorCode = error.code == kMetaNoFillErrorCode ? ERROR_NT_LOAD_NO_FILL : error.code;
        errorReason = error.description;
    } else {
        errorCode = ERROR_CODE_GENERIC;
        errorReason = @"Load attempt failed";
    }
    
    NSError *nativeAdError = [NSError errorWithDomain:kAdapterName
                                                 code:errorCode
                                             userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    
    [self.delegate adapterNativeAdDidFailToLoadWithError:nativeAdError];
}

/**
 Sent immediately before the impression of a FBNativeAd object will be logged.
 @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdWillLogImpression:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterNativeAdDidShow];
}

/**
 Sent after an ad has been clicked by the person.
 @param nativeAd A FBNativeAd object sending the message.
 */
- (void)nativeAdDidClick:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(@"placementId = %@", self.placementId);
    [self.delegate adapterNativeAdDidClick];
}

@end
