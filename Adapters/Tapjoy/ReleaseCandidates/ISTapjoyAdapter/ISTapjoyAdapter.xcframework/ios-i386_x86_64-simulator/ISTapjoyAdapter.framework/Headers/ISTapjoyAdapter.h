//
//  ISTapjoyAdapter.h
//  ISTapjoyAdapter
//
//  Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const TapjoyAdapterVersion = @"4.1.23";
static NSString * GitHash = @"9acdedd";

//System Frameworks For Tapjoy Adapter

@import AdSupport;
@import CFNetwork;
@import CoreServices;
@import CoreTelephony;
@import SystemConfiguration;
@import StoreKit;
@import UIKit;
@import WebKit;

@interface ISTapjoyAdapter : ISBaseAdapter

@end
