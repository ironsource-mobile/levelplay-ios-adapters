//
//  ISYandexAdapter.h
//  ISYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>

static NSString * const YandexAdapterVersion = @"4.3.8";
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
