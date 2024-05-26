//
//  ISBidMachineRewardedVideoDelegate.m
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISBidMachineRewardedVideoDelegate.h"
#import "ISBidMachineConstants.h"

@implementation ISBidMachineRewardedVideoDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)didLoadAd:(id<BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)didFailLoadAd:(id<BidMachineAdProtocol> _Nonnull)ad
                     :(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    NSInteger errorCode = (error.code == kBidMachineNoFillErrorCode) ? ERROR_RV_LOAD_NO_FILL : error.code;
    NSError *errorInfo = [NSError errorWithDomain:kAdapterName
                                             code:errorCode
                                         userInfo:@{NSLocalizedDescriptionKey:error.description}];
    [self.delegate adapterRewardedVideoHasChangedAvailability:NO];
    [self.delegate adapterRewardedVideoDidFailToLoadWithError:errorInfo];
}

- (void)didTrackImpression:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterRewardedVideoDidOpen];
    [self.delegate adapterRewardedVideoDidStart];
}

- (void)didFailPresentAd:(id <BidMachineAdProtocol> _Nonnull)ad
                        :(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    [self.delegate adapterRewardedVideoDidFailToShowWithError:error];
}

- (void)didUserInteraction:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterRewardedVideoDidClick];
}

-(void)didReceiveReward:(id<BidMachineAdProtocol>)ad{
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterRewardedVideoDidReceiveReward];
}

- (void)didDismissAd:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterRewardedVideoDidEnd];
    [self.delegate adapterRewardedVideoDidClose];
}

@end

