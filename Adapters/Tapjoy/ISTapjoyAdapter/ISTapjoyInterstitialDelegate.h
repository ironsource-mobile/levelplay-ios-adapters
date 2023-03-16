//
//  ISTapjoyInterstitialDelegate.h
//  ISTapjoyAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Tapjoy/TJPlacement.h>
#import <Tapjoy/Tapjoy.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISTapjoyInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialVideoDidLoad:(nonnull NSString *)placementName;

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)placementName
                           withError:(nullable NSError *)error;

- (void)onInterstitialDidOpen:(nonnull NSString *)placementName;

- (void)onInterstitialShowFail:(nonnull NSString *)placementName
              withErrorMessage:(nullable NSString *)errorMessage;

- (void)onInterstitialDidClick:(nonnull NSString *)placementName;

- (void)onInterstitialDidClose:(nonnull NSString *)placementName;

@end

@interface ISTapjoyInterstitialDelegate : NSObject <TJPlacementDelegate, TJPlacementVideoDelegate>

@property (nonatomic, strong) NSString* placementName;
@property (nonatomic, weak) id<ISTapjoyInterstitialDelegateWrapper> delegate;

- (instancetype)initWithPlacementName:(NSString *)placementName
                          andDelegate:(id<ISTapjoyInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
