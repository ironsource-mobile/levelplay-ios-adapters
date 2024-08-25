//
//  ISFacebookInterstitialDelegate.h
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <IronSource/ISBaseAdapter+Internal.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISFacebookInterstitialDelegate : NSObject <FBInterstitialAdDelegate>

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> delegate;

- (instancetype)initWithPlacementId:(NSString *)placementId
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
