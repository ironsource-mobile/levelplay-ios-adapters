//
//  ISFyberAdapter.h
//  ISFyberAdapter
//
//  Created by Gili Ariel on 14/03/2018.
//  Copyright © 2018 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const FyberAdapterVersion = @"4.3.22";
static NSString *  GitHash = @"";

//System Frameworks For Fyber Adapter

@import AdSupport;
@import AVFoundation;
@import CoreGraphics;
@import CoreMedia;
@import CoreTelephony;
@import MediaPlayer;
@import StoreKit;
@import SystemConfiguration;
@import WebKit;

@interface ISFyberAdapter : ISBaseAdapter

@end

