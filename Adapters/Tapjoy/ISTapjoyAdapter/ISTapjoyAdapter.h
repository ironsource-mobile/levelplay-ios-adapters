//
//  ISTapjoyAdapter.h
//  ISTapjoyAdapter
//
//  Created by Daniil Bystrov on 4/13/16.
//  Copyright © 2016 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const TapjoyAdapterVersion = @"4.1.21";
static NSString * GitHash = @"";

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
