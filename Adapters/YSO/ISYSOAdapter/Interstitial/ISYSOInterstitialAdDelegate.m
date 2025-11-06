//
//  ISYSOInterstitialAdDelegate.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYSOInterstitialAdapter.h"
#import "ISYSOInterstitialAdDelegate.h"

@implementation ISYSOInterstitialAdDelegate

- (instancetype)initWithPlacementKey:(NSString *)placementKey
                            adapter:(ISYSOAdapter *)adapter
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
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
        [self.delegate adapterInterstitialDidLoad];
    } else {
        NSString *loadError = [self.adapter ysoLoadErrorToString:error];
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:(NSInteger)error
                                              userInfo:@{NSLocalizedDescriptionKey:loadError}];
        LogAdapterDelegate_Internal(@"placementKey = %@ with error = %@", self.placementKey, loadError);
        [self.delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void)handleOnDisplay:(YNWebView *)view {
    LogAdapterDelegate_Internal(@"placementKey = %@", self.placementKey);
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

- (void)handleOnClick {
    LogAdapterDelegate_Internal(@"placementKey = %@", self.placementKey);
    [self.delegate adapterInterstitialDidClick];
}

- (void)handleOnClose:(BOOL)display complete:(BOOL)complete {
    if (!display){
        NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                  withMessage:[NSString stringWithFormat:@"%@ show failed", kAdapterName]];
        LogAdapterDelegate_Internal(@"calling adapterInterstitialDidFailToShowWithError for placementKey = %@, error = %@", self.placementKey, error);
        [self.delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    LogAdapterDelegate_Internal(@"calling adapterInterstitialDidClose for placementKey = %@", self.placementKey);
    [self.delegate adapterInterstitialDidClose];
}

@end
