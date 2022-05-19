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

@protocol ISHyperMXISDelegateWrapper <NSObject>

- (void)adWillStartForIsProperty:(NSString *)propertyId;
- (void)adDidCloseForIsProperty:(NSString *)propertyId
                    didFinishAd:(BOOL)finished;
- (void)adDisplayErrorForIsProperty:(NSString *)propertyId
                              error:(HyprMXError)hyprMXError;
- (void)adAvailableForIsProperty:(NSString *)propertyId;
- (void)adNotAvailableForIsProperty:(NSString *)propertyId;
- (void)adExpiredForIsProperty:(NSString *)propertyId;

@end

@interface ISHyprMXIsListener : NSObject <HyprMXPlacementDelegate>

@property (nonatomic, strong) NSString* propertyId;
@property (nonatomic, weak) id<ISHyperMXISDelegateWrapper> delegate;

- (instancetype)initWithPropertyId:(NSString *)propertyId
                       andDelegate:(id<ISHyperMXISDelegateWrapper>)delegate;

@end

NS_ASSUME_NONNULL_END
