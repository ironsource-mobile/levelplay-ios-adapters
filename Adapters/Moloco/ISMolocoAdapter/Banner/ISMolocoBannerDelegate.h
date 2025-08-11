//
//  ISMolocoBannerDelegate.h
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

@interface ISMolocoBannerDelegate : NSObject <MolocoBannerDelegate>

@property (nonatomic, strong) NSString* adUnitId;
@property (nonatomic, weak) id<ISBannerAdapterDelegate> delegate;

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate;
@end
