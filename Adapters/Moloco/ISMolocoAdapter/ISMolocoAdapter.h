//
//  ISMolocoAdapter.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const MolocoAdapterVersion = @"5.15.0";
static NSString * Githash = @"";

// System Frameworks For Moloco Adapter
@import AdSupport;
@import AVFoundation;
@import CoreGraphics;
@import CoreMedia;
@import CoreTelephony;
@import SafariServices;
@import StoreKit;
@import SystemConfiguration;

@interface ISMolocoAdapter : LevelPlayBaseAdapter

@end
