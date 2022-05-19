//
//  ISHyprMXRvListener.h
//  ISHyprMXAdapter
//
//  Created by Roni Schwartz on 16/12/2018.
//  Copyright © 2018 Supersonic. All rights reserved.
//

#import <HyprMX/HyprMX.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ISHyperMXRVDelegateWrapper <NSObject>

- (void)adWillStartForRvProperty:(NSString *)propertyId;
- (void)adDidCloseForRvProperty:(NSString *)propertyId
                    didFinishAd:(BOOL)finished;
- (void)adDisplayErrorForRvProperty:(NSString *)propertyId
                              error:(HyprMXError)hyprMXError;
- (void)adAvailableForRvProperty:(NSString *)propertyId;
- (void)adNotAvailableForRvProperty:(NSString *)propertyId;
- (void)adDidRewardForRvProperty:(NSString *)propertyId
                      rewardName:(NSString *)rewardName
                     rewardValue:(NSInteger)rewardValue;
- (void)adExpiredForRvProperty:(NSString *)propertyId;

@end

@interface ISHyprMXRvListener : NSObject <HyprMXPlacementDelegate>

@property (nonatomic, strong) NSString* propertyId;
@property (nonatomic, weak) id<ISHyperMXRVDelegateWrapper> delegate;

- (instancetype)initWithPropertyId:(NSString *)propertyId
                       andDelegate:(id<ISHyperMXRVDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
