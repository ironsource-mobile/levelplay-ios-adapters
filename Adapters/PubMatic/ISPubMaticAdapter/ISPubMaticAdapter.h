//
//  ISPubMaticAdapter.h
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>

static NSString * const PubMaticAdapterVersion = @"5.0.0";
static NSString * Githash = @"";

//System Frameworks For PubMatic Adapter
@import AdSupport;
@import AppTrackingTransparency;
@import AVFoundation;
@import AVKit;
@import CoreFoundation;
@import CoreGraphics;
@import CoreLocation;
@import CoreMedia;
@import CoreTelephony;
@import EventKit;
@import EventKitUI;
@import Foundation;
@import MessageUI;
@import Network;
@import QuartzCore;
@import SafariServices;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import WebKit;

@interface ISPubMaticAdapter : ISBaseAdapter

@end
