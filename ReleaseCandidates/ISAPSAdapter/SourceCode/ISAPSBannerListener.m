//
//  ISAPSBannerListener.m
//  ISAPSAdapter
//
//  Created by Sveta Itskovich on 14/12/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISAPSBannerListener.h"

@implementation ISAPSBannerListener

-(instancetype)initWithPlacementID:(NSString *)placementID andDelegate:(id<ISAPSBNSDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _placementID = placementID;
    }
    return self;
}
- (void)adDidLoad:(UIView * _Nonnull)adView{
    [_delegate bannerAdDidLoad:_placementID withBanner:adView];
}

- (void)adFailedToLoad:(UIView * _Nullable)banner errorCode:(NSInteger)errorCode{
    [_delegate bannerAdFailedToLoad:_placementID errorCode:errorCode];
}

- (void)bannerWillLeaveApplication:(UIView *)adView{
    [_delegate bannerWillLeaveApplication:_placementID];
}

- (void)impressionFired {
    [_delegate bannerImpressionFired:_placementID];
}

@end
