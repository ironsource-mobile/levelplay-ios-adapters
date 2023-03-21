//
//  ISPangleBannerDelegate.h
//  ISPangleAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISPangleBannerDelegateWrapper <NSObject>

- (void)onBannerDidLoad:(nonnull NSString *)slotId;

- (void)onBannerDidFailToLoad:(nonnull NSString *)slotId
                    withError:(nonnull NSError *)error;

- (void)onBannerDidShow:(nonnull NSString *)slotId;

- (void)onBannerDidClick:(nonnull NSString *)slotId;

@end

@interface ISPangleBannerDelegate : NSObject <PAGBannerAdDelegate>

@property (nonatomic, strong) NSString *slotId;
@property (nonatomic, weak) id<ISPangleBannerDelegateWrapper> delegate;

- (instancetype)initWithSlotId:(NSString *)slotId
                   andDelegate:(id<ISPangleBannerDelegateWrapper>)delegate;
@end

NS_ASSUME_NONNULL_END
