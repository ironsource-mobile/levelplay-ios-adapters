//
//  ISVoodooInterstitialDelegate.h
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VoodooAdn/VoodooAdn.h>
#import <IronSource/ISBaseAdapter+Internal.h>

@interface ISVoodooInterstitialDelegate : NSObject<AdnFullscreenAdDelegate>

@property (nonatomic, strong) NSString                        *placementId;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

- (void)handleOnLoad:(NSError *)error;

@end
