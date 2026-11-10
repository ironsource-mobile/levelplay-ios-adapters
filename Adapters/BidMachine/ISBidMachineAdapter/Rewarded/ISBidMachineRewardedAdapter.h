//
//  ISBidMachineRewardedAdapter.h
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/LevelPlayBaseRewardedAdapter.h>
#import <BidMachine/BidMachine-Swift.h>

@interface ISBidMachineRewardedAdapter : LevelPlayBaseRewardedAdapter

- (void)setRewardedAd:(BidMachineRewarded *)ad;

@end
