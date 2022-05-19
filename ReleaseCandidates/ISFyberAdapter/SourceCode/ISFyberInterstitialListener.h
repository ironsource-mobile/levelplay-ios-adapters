//
//  ISFyberInterstitialListener.h
//  ISFyberAdapter
//
//  Created by Guy Lis on 27/08/2019.
//  Copyright © 2019 IronSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IASDKCore/IASDKCore.h>
#import <IASDKCore/IASDKVideo.h>
#import <IASDKCore/IASDKMRAID.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISInterstitialAdapterDelegate;

@protocol ISFyberInterstitialDelegateWrapper <NSObject>

- (void)onInterstitialDidShow:(NSString *)spotId;
- (void)onInterstitialDidClick:(NSString *)spotId;
- (void)onInterstitialShowFailed:(NSString *)spotId
                       withError:(NSError *)error;
- (void)onInterstitialDidClose:(NSString *)spotId;

@end

@interface ISFyberInterstitialListener : NSObject <IAUnitDelegate, IAVideoContentDelegate, IAMRAIDContentDelegate>

@property (nonatomic, strong) NSString *spotId;
@property (nonatomic, weak)   id<ISFyberInterstitialDelegateWrapper> delegate;
@property (nonatomic, weak)   UIViewController *viewControllerForPresentingModalView;

- (instancetype)initWithSpotId:(NSString *)spotId
                   andDelegate:(id<ISFyberInterstitialDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
