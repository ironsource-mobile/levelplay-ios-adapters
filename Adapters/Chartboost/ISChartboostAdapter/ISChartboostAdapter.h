//
//  ISChartboostAdapter.h
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>

static NSString * const ChartboostAdapterVersion = @"4.3.24";
static NSString * Githash = @"";

//System Frameworks For Chartboost Adapter

@import AdSupport;
@import AVFoundation;
@import CoreGraphics;
@import CoreMedia;
@import StoreKit;
@import UIKit;
@import WebKit;

@interface ISChartboostAdapter : ISBaseAdapter

@end
