//
//  ISUADSRewardedShowDelegate.m
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISUADSRewardedShowDelegate.h"

@interface ISUADSRewardedShowDelegate()
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> _Nullable delegate;
@property (nonatomic, strong) NSString * _Nonnull placementId;
@end

@implementation ISUADSRewardedShowDelegate

-(instancetype)initWithPlacementId:(NSString *)placementId
                          delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    self = [super init];
    
    if (self) {
        self.placementId = placementId;
        self.delegate = delegate;
    }
    
    return self;
}

- (void)showDidStart:(UnityAd * _Nonnull)unityAd {
    LogAdapterDelegate_Internal(@"placementId = %@", _placementId);
    
    [_delegate adapterRewardedVideoDidOpen];
    [_delegate adapterRewardedVideoDidStart];
}

- (void)showDidClick:(UnityAd * _Nonnull)unityAd {
    LogAdapterDelegate_Internal(@"placementId = %@", _placementId);
    
    [_delegate adapterRewardedVideoDidClick];
}

- (void)showDidReceiveReward:(UnityAd * _Nonnull)unityAd {
    LogAdapterDelegate_Internal(@"placementId = %@", _placementId);
    
    [_delegate adapterRewardedVideoDidReceiveReward];
}

- (void)showDidComplete:(UnityAd * _Nonnull)unityAd with:(enum UADSShowFinishState)finishState {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", _placementId, (int)finishState);
    
    if (finishState == UADSShowFinishStateCompleted) {
        [_delegate adapterRewardedVideoDidEnd];
    }
    [_delegate adapterRewardedVideoDidClose];
}

- (void)showDidFail:(UnityAd * _Nonnull)unityAd error:(id<UnityAdsError> _Nonnull)error {
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %ld %@", _placementId, error.code, error.message);
  
    NSError *smashError = [NSError errorWithDomain:UnityAdsAdapterName
                                              code:error.code
                                          userInfo:@{NSLocalizedDescriptionKey:error.message}];
    [_delegate adapterRewardedVideoDidFailToShowWithError:smashError];
}

@end
