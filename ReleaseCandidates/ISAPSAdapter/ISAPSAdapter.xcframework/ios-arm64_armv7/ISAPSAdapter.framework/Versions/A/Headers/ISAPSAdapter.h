//
//  ISAPSAdapter.h
//  ISAPSAdapter
//
//  Created by Sveta Itskovich on 11/11/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const APSAdapterVersion = @"4.3.2";
static NSString * GitHash = @"";

@import CoreTelephony;
@import EventKit;
@import EventKitUI;
@import MediaPlayer;
@import StoreKit;
@import SystemConfiguration;
@import QuartzCore;

@interface ISAPSAdapter : ISBaseAdapter

@end

