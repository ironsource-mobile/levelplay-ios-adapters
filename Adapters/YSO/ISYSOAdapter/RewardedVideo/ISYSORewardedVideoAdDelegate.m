//
//  ISYSORewardedVideoAdDelegate.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYSORewardedVideoAdapter.h"
#import "ISYSORewardedVideoAdDelegate.h"

@implementation ISYSORewardedVideoAdDelegate

- (instancetype)initWithPlacementKey:(NSString *)placementKey
                            adapter:(ISYSOAdapter *)adapter
                    andDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _placementKey = placementKey;
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Callback Handlers

- (void)handleOnLoad:(e_ActionError)error {
    if (error == e_ActionErrorNone)
    {
        LogAdapterDelegate_Internal(@"placementKey = %@", self.placementKey);
        [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
    } else {
        NSString *loadError = [self.adapter ysoLoadErrorToString:error];
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:(NSInteger)error
                                              userInfo:@{NSLocalizedDescriptionKey:loadError}];
        LogAdapterDelegate_Internal(@"placementKey = %@ with error = %@", self.placementKey, loadError);
        [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
        [self.delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    }
}

- (void)handleOnDisplay:(YNWebView *)view {
    LogAdapterDelegate_Internal(@"placementKey = %@", self.placementKey);
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

- (void)handleOnClick {
    LogAdapterDelegate_Internal(@"placementKey = %@", self.placementKey);
    [self.delegate adapterRewardedVideoDidClick];
}

- (void)handleOnClose:(BOOL)display complete:(BOOL)complete {
    if(!display){
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
        LogAdapterDelegate_Internal(@"calling adapterRewardedVideoDidFailToShowWithError for placementKey = %@, error = %@", self.placementKey, error);
        [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    if(complete){
        LogAdapterDelegate_Internal(@"calling adapterRewardedVideoDidReceiveReward for placementKey = %@", self.placementKey);
        [self.delegate adapterRewardedVideoDidEnd];
        [self.delegate adapterRewardedVideoDidReceiveReward];
    }
    LogAdapterDelegate_Internal(@"calling adapterRewardedVideoDidClose for placementKey = %@", self.placementKey);
    [self.delegate adapterRewardedVideoDidClose];
}

@end
