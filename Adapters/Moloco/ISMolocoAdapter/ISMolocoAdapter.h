//
//  ISMolocoAdapter.h
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>

static NSString * const MolocoAdapterVersion = @"4.3.8";
static NSString * Githash = @"";

//System Frameworks For Moloco Adapter
@import AdSupport;
@import AVFoundation;
@import CoreGraphics;
@import CoreMedia;
@import CoreTelephony;
@import SafariServices;
@import StoreKit;
@import SystemConfiguration;


@interface ISMolocoAdapter : ISBaseAdapter

@end
