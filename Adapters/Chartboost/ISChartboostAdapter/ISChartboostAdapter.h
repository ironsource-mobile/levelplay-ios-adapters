//
// Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"
#import "IronSource/IronSource.h"

static NSString * const ChartboostAdapterVersion = @"4.3.12";
static NSString * Githash = @"8d9eaa9";

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
