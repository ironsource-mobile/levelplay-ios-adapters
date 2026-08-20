//
//  ISYSOAdapter.h
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/LevelPlayBaseAdapter.h>
#import <IronSource/IronSource.h>

static NSString * const YSOAdapterVersion = @"5.2.0";
static NSString * Githash = @"";

//System Frameworks For YSO Adapter
@import AdSupport;
@import CoreFoundation;
@import CoreGraphics;
@import StoreKit;
@import UIKit;
@import WebKit;

@interface ISYSOAdapter : LevelPlayBaseAdapter

@end
