//
//  ISBidMachineBannerDelegate.m
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISBidMachineBannerDelegate.h"
#import "ISBidMachineConstants.h"

@implementation ISBidMachineBannerDelegate

- (instancetype)initWithBanner:(BidMachineBanner *)banner
                   andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    
    if (self) {
        _banner = banner;
        _delegate = delegate;
    }
    
    return self;
}

- (void)didLoadAd:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterBannerDidLoad:self.banner];
}

- (void)didFailLoadAd:(id <BidMachineAdProtocol> _Nonnull)ad
                     :(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    NSInteger errorCode = (error.code == kBidMachineNoFillErrorCode) ? ERROR_BN_LOAD_NO_FILL : error.code;
    NSError *errorInfo = [NSError errorWithDomain:kAdapterName
                                             code:errorCode
                                         userInfo:@{NSLocalizedDescriptionKey:error.description}];
    [self.delegate adapterBannerDidFailToLoadWithError:errorInfo];
}

- (void)didTrackImpression:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterBannerDidShow];
}

- (void)didUserInteraction:(id <BidMachineAdProtocol> _Nonnull)ad {
    LogAdapterDelegate_Internal(@"");
    [self.delegate adapterBannerDidClick];
}

@end
