//
//  ISUADSInterstitialShowDelegate.m
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISUADSInterstitialShowDelegate.h"

@interface ISUADSInterstitialShowDelegate()
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> _Nullable delegate;
@property (nonatomic, strong) NSString * _Nonnull placementId;
@end

@implementation ISUADSInterstitialShowDelegate

-(instancetype)initWithPlacementId:(NSString *)placementId
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    self = [super init];
    
    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
    }
    
    return self;
}

- (void)showDidStart:(UnityAd * _Nonnull)unityAd {
    LogAdapterDelegate_Internal(@"placementId = %@", _placementId);
   
    [_delegate adapterInterstitialDidOpen];
    [_delegate adapterInterstitialDidShow];
}

- (void)showDidClick:(UnityAd * _Nonnull)unityAd {
    LogAdapterDelegate_Internal(@"placementId = %@", _placementId);
    
    [_delegate adapterInterstitialDidClick];
}

- (void)showDidComplete:(UnityAd * _Nonnull)unityAd with:(enum UADSShowFinishState)finishState {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", _placementId, (int)finishState);
  
    [_delegate adapterInterstitialDidClose];
}

- (void)showDidFail:(UnityAd * _Nonnull)unityAd error:(id<UnityAdsError> _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %ld %@", _placementId, error.code, error.message);
  
    NSError *smashError = [NSError errorWithDomain:UnityAdsAdapterName
                                              code:error.code
                                          userInfo:@{NSLocalizedDescriptionKey:error.message}];
    [_delegate adapterInterstitialDidFailToShowWithError:smashError];
}

@end
