//
//  ISBidMachineInterstitialDelegate.m
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISBidMachineInterstitialDelegate.h"
#import "ISBidMachineConstants.h"

@implementation ISBidMachineInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)didLoadAd:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterInterstitialDidLoad];
}

- (void)didFailLoadAd:(id <BidMachineAdProtocol> _Nonnull)ad
                     :(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    NSInteger errorCode = (error.code == kBidMachineNoFillErrorCode) ? ERROR_IS_LOAD_NO_FILL : error.code;
    NSError *errorInfo = [NSError errorWithDomain:kAdapterName
                                             code:errorCode
                                         userInfo:@{NSLocalizedDescriptionKey:error.description}];
    [self.delegate adapterInterstitialDidFailToLoadWithError:errorInfo];
}

- (void)didTrackImpression:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterInterstitialDidOpen];
    [self.delegate adapterInterstitialDidShow];
}

- (void)didFailPresentAd:(id <BidMachineAdProtocol> _Nonnull)ad
                        :(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    [self.delegate adapterInterstitialDidFailToShowWithError:error];
}

- (void)didUserInteraction:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterInterstitialDidClick];
}

- (void)didDismissAd:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterInterstitialDidClose];
}

@end
