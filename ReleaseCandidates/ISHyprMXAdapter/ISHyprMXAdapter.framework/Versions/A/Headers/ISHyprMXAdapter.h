//
//  Copyright (c) 2015 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"
#import "IronSource/ISGlobals.h"

static NSString * const HyprMXAdapterVersion = @"4.1.11";
static NSString * GitHash = @"";

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

@interface ISHyprMXAdapter : ISBaseAdapter

@end
