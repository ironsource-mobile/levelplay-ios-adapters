//
//  ISAPSBannerDelegate.h
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

@protocol ISBannerAdDelegate;

@interface ISAPSBannerDelegate : NSObject <DTBAdBannerDispatcherDelegate>

@property (nonatomic, weak) id<ISBannerAdDelegate> delegate;
@property (nonatomic, copy) NSString *creativeId;

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate
                      creativeId:(NSString *)creativeId;

@end
