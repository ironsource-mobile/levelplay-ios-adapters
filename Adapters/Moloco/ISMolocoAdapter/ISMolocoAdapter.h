//
//  ISMolocoAdapter.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>

static NSString * const MolocoAdapterVersion = @"5.1.0";
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
