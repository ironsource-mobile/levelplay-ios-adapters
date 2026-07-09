//
//  ISYSOAdapter.h
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>

static NSString * const YSOAdapterVersion = @"5.1.0";
static NSString * Githash = @"";

//System Frameworks For YSO Adapter
@import AdSupport;
@import CoreFoundation;
@import CoreGraphics;
@import Foundation;
@import StoreKit;
@import UIKit;
@import WebKit;

@interface ISYSOAdapter : ISBaseAdapter

@end
