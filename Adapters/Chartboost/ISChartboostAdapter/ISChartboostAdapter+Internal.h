//
//  ISChartboostAdapter+Internal.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISChartboostAdapter.h"
#import "ISChartboostConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBiddingDataProtocol.h>
#import <ChartboostSDK/ChartboostSDK.h>

@interface ISChartboostAdapter ()

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate;

- (CHBMediation *)getMediationInfo;

@end
