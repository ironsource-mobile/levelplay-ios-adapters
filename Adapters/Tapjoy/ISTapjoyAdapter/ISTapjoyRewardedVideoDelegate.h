//
//  ISTapjoyRewardedVideoDelegate.h
//  ISTapjoyAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Tapjoy/TJPlacement.h>
#import <Tapjoy/Tapjoy.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISTapjoyRewardedVideoDelegateWrapper <NSObject>

- (void)onRewardedVideoDidLoad:(nonnull NSString *)placementName;

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)placementName
                           withError:(nullable NSError *)error;

- (void)onRewardedVideoDidOpen:(nonnull NSString *)placementName;

- (void)onRewardedVideoShowFail:(nonnull NSString *)placementName
               withErrorMessage:(nullable NSString *)errorMessage;

- (void)onRewardedVideoDidClick:(nonnull NSString *)placementName;

- (void)onRewardedVideoDidEnd:(nonnull NSString *)placementName;

- (void)onRewardedVideoDidClose:(nonnull NSString *)placementName;

@end

@interface ISTapjoyRewardedVideoDelegate : NSObject <TJPlacementDelegate, TJPlacementVideoDelegate>

@property (nonatomic, strong) NSString* placementName;
@property (nonatomic, weak) id<ISTapjoyRewardedVideoDelegateWrapper> delegate;

- (instancetype)initWithPlacementName:(NSString *)placementName
                          andDelegate:(id<ISTapjoyRewardedVideoDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
