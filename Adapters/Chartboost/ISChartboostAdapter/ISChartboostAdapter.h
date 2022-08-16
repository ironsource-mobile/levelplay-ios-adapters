//
//  Copyright (c) 2015 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const ChartboostAdapterVersion = @"4.3.11";
static NSString * Githash = @"772c06b";

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
