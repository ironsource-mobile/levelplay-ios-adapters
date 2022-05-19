//
//  ISHyprMXRvListener.m
//  ISHyprMXAdapter
//
//  Created by Roni Schwartz on 16/12/2018.
//  Copyright © 2018 Supersonic. All rights reserved.
//

#import "ISHyprMXRvListener.h"

@implementation ISHyprMXRvListener


- (instancetype)initWithPropertyId:(NSString *)propertyId
                       andDelegate:(id<ISHyperMXRVDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _propertyId = propertyId;
        _delegate = delegate;
    }
    return self;
}

/**
 * The ad is about to start showing
 * @param placement The placement being shown
 */
- (void)adWillStartForPlacement:(nonnull HyprMXPlacement *)placement {
    [_delegate adWillStartForRvProperty:_propertyId];
}

/**
 * Presentation related to this placement has finished.
 * @param placement The placement that presented
 * @param finished true if ad was finished, false if it was canceled
 */
- (void)adDidCloseForPlacement:(nonnull HyprMXPlacement *)placement
                   didFinishAd:(BOOL)finished {
    [_delegate adDidCloseForRvProperty:_propertyId didFinishAd:finished];
}

/**
 * An ad is available for the placement
 * @param placement The placement that was loaded
 */
- (void)adAvailableForPlacement:(nonnull HyprMXPlacement *)placement {
    [_delegate adAvailableForRvProperty:_propertyId];
}

/**
 * There is no fill for the placement
 * @param placement The placement that was loaded
 */
- (void)adNotAvailableForPlacement:(nonnull HyprMXPlacement *)placement {
    [_delegate adNotAvailableForRvProperty:_propertyId];
}

/**
 * There was an error with the placement during presentation.
 * @note You can use either this method or adDisplayError:placement: to receive error events, but this method will be deprecated in the future.
 *
 * @param placement The placement with the error
 * @param hyprMXError The error that occured
 */
- (void)adDisplayErrorForPlacement:(nonnull HyprMXPlacement *)placement
                             error:(HyprMXError)hyprMXError {
    [_delegate adDisplayErrorForRvProperty:_propertyId error:hyprMXError];
}

/**
 * The ad was rewarded for the placement and will be called before ad finished is called
 * This will only be called for rewarded placements
 * @param placement The placement that was rewarded
 * @param rewardName The name of the reward
 * @param rewardValue The value of the reward
 */
- (void)adDidRewardForPlacement:(nonnull HyprMXPlacement *)placement
                     rewardName:(NSString *)rewardName
                    rewardValue:(NSInteger)rewardValue {
    [_delegate adDidRewardForRvProperty:_propertyId rewardName:rewardName rewardValue:rewardValue];
}

/**
 * An ad is no longer available for the placement
 * @param placement The placement that expired
 */
- (void)adExpiredForPlacement:(nonnull HyprMXPlacement *)placement {
    [_delegate adExpiredForRvProperty:_propertyId];
}

@end
