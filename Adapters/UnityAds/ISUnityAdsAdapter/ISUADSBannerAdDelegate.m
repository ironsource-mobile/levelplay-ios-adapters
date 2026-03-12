//
//  ISUADSBannerAdDelegate.m
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISUADSBannerAdDelegate.h"

@interface ISUADSBannerAdDelegate()
@property (nonatomic, weak) id<ISBannerAdapterDelegate> _Nullable delegate;
@property (nonatomic, strong) NSString * _Nonnull placementId;
@end

@implementation ISUADSBannerAdDelegate

-(instancetype)initWithPlacementId:(NSString *)placementId
                          delegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    
    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
    }
    
    return self;
}

- (void)bannerImpression:(UADSBannerAd * _Nonnull)banner {
    LogAdapterDelegate_Internal(@"placementId = %@", _placementId);
    [_delegate adapterBannerDidShow];
}

- (void)bannerDidClick:(UADSBannerAd * _Nonnull)banner { 
    LogAdapterDelegate_Internal(@"placementId = %@", _placementId);
    [_delegate adapterBannerDidClick];
}

- (void)bannerDidFailShow:(UADSBannerAd * _Nonnull)banner error:(id<UnityAdsError> _Nonnull)error { 
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %ld %@", _placementId, error.code, error.message);
  
    NSError *smashError = [NSError errorWithDomain:UnityAdsAdapterName
                                              code:error.code
                                          userInfo:@{NSLocalizedDescriptionKey:error.message}];
    [_delegate adapterBannerDidFailToShowWithError:smashError];
}

@end
