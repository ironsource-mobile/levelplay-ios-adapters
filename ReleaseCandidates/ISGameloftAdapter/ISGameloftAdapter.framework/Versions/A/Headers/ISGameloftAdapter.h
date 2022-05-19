//
//  ISGameloftAdapter.h
//  ISGameloftAdapter
//
//  Created by Hadar Pur on 02/08/2020.
//

#import <Foundation/Foundation.h>
#import "IronSource/ISBaseAdapter+Internal.h"

static NSString * const GameloftAdapterVersion = @"4.3.2";
static NSString *  GitHash = @"";

//System Frameworks For Gameloft Adapter

@import CoreTelephony;
@import iAd;
@import MultipeerConnectivity;
@import Photos;
@import SystemConfiguration;
@import UserNotifications;
@import WebKit;

@interface ISGameloftAdapter : ISBaseAdapter

@end
