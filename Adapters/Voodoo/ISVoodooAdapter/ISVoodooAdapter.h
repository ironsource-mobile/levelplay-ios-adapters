//
//  ISVoodooAdapter.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>

static NSString * const VoodooAdapterVersion = @"5.0.0";
static NSString * Githash = @"";

//System Frameworks For Voodoo Adapter
@import AdSupport;
@import AppTrackingTransparency;
@import AVFoundation;
@import CoreTelephony;
@import Foundation;
@import Network;
@import QuartzCore;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import WebKit;

@interface ISVoodooAdapter : ISBaseAdapter

@end
