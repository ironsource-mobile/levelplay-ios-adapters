//
//  ISFacebookInterstitialDelegate.h
//  ISFacebookAdapter
//
//  Created by Hadar Pur on 01/08/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISFacebookInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidLoad:(nonnull NSString *)placementID;

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)placementID
                          withError:(nullable NSError *)error;

- (void)onInterstitialDidOpen:(nonnull NSString *)placementID;

- (void)onInterstitialDidClick:(nonnull NSString *)placementID;

- (void)onInterstitialDidClose:(nonnull NSString *)placementID;

@end

@interface ISFacebookInterstitialDelegate : NSObject <FBInterstitialAdDelegate>

@property (nonatomic, strong) NSString* placementID;
@property (nonatomic, weak) id<ISFacebookInterstitialDelegateWrapper> delegate;

- (instancetype)initWithPlacementID:(NSString *)placementID
                        andDelegate:(id<ISFacebookInterstitialDelegateWrapper>)delegate;

@end


NS_ASSUME_NONNULL_END
