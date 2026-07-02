//
//  ISHyprMXAdapter.h
//  ISHyprMXAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const HyprMXAdapterVersion = @"5.4.0";
static NSString * Githash = @"";

//System Frameworks For HyprMX Adapter

@import AdSupport;
@import AVFoundation;
@import CoreGraphics;
@import CoreMedia;
@import CoreTelephony;
@import EventKit;
@import EventKitUI;
@import Foundation;
@import JavaScriptCore;
@import MessageUI;
@import MobileCoreServices;
@import QuartzCore;
@import SafariServices;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import WebKit;

@interface ISHyprMXAdapter : LevelPlayBaseAdapter

@end
