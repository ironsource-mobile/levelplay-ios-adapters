//
//  ISFacebookAdapter.h
//  ISFacebookAdapter
//
//  Created by Yotam Ohayon on 02/02/2016.
//  Copyright © 2016 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const FacebookAdapterVersion = @"4.3.37";
static NSString * Githash = @"7c694f7";

//System Frameworks For Facebook Adapter
@import AdSupport;
@import AudioToolbox;
@import AVFoundation;
@import CFNetwork;
@import CoreGraphics;
@import CoreImage;
@import CoreMedia;
@import CoreMotion;
@import CoreTelephony;
@import LocalAuthentication;
@import SafariServices;
@import Security;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import VideoToolbox;
@import WebKit;

@interface ISFacebookAdapter : ISBaseAdapter

@end
