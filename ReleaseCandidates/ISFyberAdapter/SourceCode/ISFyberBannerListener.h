//
//  ISFyberBannerListener.h
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

@protocol ISBannerAdapterDelegate;

@protocol ISFyberBannerDelegateWrapper <NSObject>

- (void)onBannerDidShow:(NSString *)spotId;
- (void)onBannerDidShowFailed:(NSString *)spotId
                    withError:(NSError *)error;
- (void)onBannerDidClick:(NSString *)spotId;
- (void)onBannerBannerWillLeaveApplication:(NSString *)spotId;

@end

@interface ISFyberBannerListener : NSObject <IAUnitDelegate, IAVideoContentDelegate, IAMRAIDContentDelegate>

@property (nonatomic, strong) NSString *spotId;
@property (nonatomic, weak)   id<ISFyberBannerDelegateWrapper> delegate;
@property (nonatomic, weak)   UIViewController *viewControllerForPresentingModalView;

- (instancetype)initWithSpotId:(NSString *)spotId
                   andDelegate:(id<ISFyberBannerDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
