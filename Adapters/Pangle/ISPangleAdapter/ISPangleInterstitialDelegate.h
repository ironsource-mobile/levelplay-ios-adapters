//
//  ISPangleInterstitialDelegate.h
//  ISPangleAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISPangleInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidLoad:(nonnull NSString *)slotId;

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)slotId
                          withError:(nonnull NSError *)error;

- (void)onInterstitialDidOpen:(nonnull NSString *)slotId;

- (void)onInterstitialDidClick:(nonnull NSString *)slotId;

- (void)onInterstitialDidClose:(nonnull NSString *)slotId;

@end

@interface ISPangleInterstitialDelegate : NSObject<PAGLInterstitialAdDelegate>

@property (nonatomic, strong) NSString *slotId;
@property (nonatomic, weak) id<ISPangleInterstitialDelegateWrapper> delegate;

- (instancetype)initWithSlotId:(NSString *)slotId
                   andDelegate:(id<ISPangleInterstitialDelegateWrapper>)delegate;
@end

NS_ASSUME_NONNULL_END
