//
//  ISBidMachineInterstitialAdapter.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/LevelPlayBaseInterstitialAdapter.h>
#import <BidMachine/BidMachine-Swift.h>

@interface ISBidMachineInterstitialAdapter : LevelPlayBaseInterstitialAdapter

- (void)setInterstitialAd:(BidMachineInterstitial *)ad;

@end
