//
//  ISMaioAdapter.h
//  ISMaioAdapter
//
//  Created by Dor Alon on 16/10/2017.
//  Copyright © 2017 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const MaioAdapterVersion = @"4.1.10";
static NSString * GitHash = @"";

//System Frameworks For Maio Adapter
@import AdSupport;
@import AVFoundation;
@import CoreMedia;
@import MobileCoreServices;
@import StoreKit;
@import SystemConfiguration;
@import UIKit;
@import WebKit;

@interface ISMaioAdapter : ISBaseAdapter

@end
