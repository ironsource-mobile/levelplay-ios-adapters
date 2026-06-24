//
//  ISPangleAdapter.h
//  ISPangleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const PangleAdapterVersion = @"5.29.0";
static NSString * Githash = @"";

// System Frameworks For Pangle Adapter
@import Accelerate;
@import AdSupport;
@import AppTrackingTransparency;
@import AudioToolbox;
@import AVFoundation;
@import CoreGraphics;
@import CoreImage;
@import CoreLocation;
@import CoreMedia;
@import CoreML;
@import CoreMotion;
@import CoreTelephony;
@import CoreText;
@import ImageIO;
@import JavaScriptCore;
@import MapKit;
@import MediaPlayer;
@import MobileCoreServices;
@import QuartzCore;
@import Security;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import WebKit;

@interface ISPangleAdapter : LevelPlayBaseAdapter

@end
