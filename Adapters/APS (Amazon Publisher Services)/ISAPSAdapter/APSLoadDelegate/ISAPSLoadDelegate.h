//
//  ISAPSLoadDelegate.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@protocol ISBiddingDataDelegate;

@interface ISAPSLoadDelegate : NSObject <DTBAdCallback>

- (instancetype)initWithDelegate:(id<ISBiddingDataDelegate>)delegate
                      completion:(void (^)(DTBAdResponse *))completion;

@end
