//
//  ISYandexAdapter.h
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>

static NSString * const YandexAdapterVersion = @"5.5.0";
static NSString * Githash = @"";

//System Frameworks For Yandex Adapter
@import AdSupport;
@import AVFoundation;
@import CoreGraphics;
@import CoreImage;
@import CoreLocation;
@import CoreMedia;
@import CoreTelephony;
@import Foundation;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import QuartzCore;

@interface ISYandexAdapter : ISBaseAdapter

@end
