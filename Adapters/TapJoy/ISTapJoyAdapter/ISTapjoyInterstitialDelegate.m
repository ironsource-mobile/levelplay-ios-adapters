//
//  ISTapjoyInterstitialListener.m
//  ISTapjoyAdapter
//
//  Created by Hadar Pur on 06/07/2022.
//  Copyright © 2022 ironSource. All rights reserved.
//

#import "ISTapjoyInterstitialDelegate.h"

static NSInteger const LOAD_ERROR_NOT_AVAILABLE = 5001;

@implementation ISTapjoyInterstitialDelegate

- (instancetype)initWithPlacementName:(NSString *)placementName
                          andDelegate:(id<ISTapjoyInterstitialDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _placementName = placementName;
        _delegate = delegate;
    }
    return self;
}

/**
 * Callback issued by TJ to publisher to state that placement request is successful
 * @param placement The TJPlacement that was sent
 */
- (void)requestDidSucceed:(TJPlacement *)placement {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (placement.isContentAvailable) {
            return;
        }
        
        NSError *error = [NSError errorWithDomain:@"Tapjoy"
                                             code:LOAD_ERROR_NOT_AVAILABLE
                                         userInfo:@{NSLocalizedDescriptionKey : @"No content available"}];

        [_delegate onInterstitialDidFailToLoad:_placementName
                                      withError:error];
    });
}

/**
 * Called when an error occurs while sending the placement
 * @param placement The TJPlacement that was sent
 * @param error error code
 */
- (void)requestDidFail:(TJPlacement *)placement
                 error:(NSError *)error {
    [_delegate onInterstitialDidFailToLoad:_placementName
                                  withError:error];
}

/**
 * Called when content for an placement is successfully cached
 * @param placement The TJPlacement that was sent
 */
- (void)contentIsReady:(TJPlacement *)placement {
    [_delegate onInterstitialVideoDidLoad:_placementName];
}

/**
 * Called when a placement video starts playing.
 * @param placement The TJPlacement that was sent
 */
- (void)videoDidStart:(TJPlacement *)placement{
    [_delegate onInterstitialDidOpen:_placementName];
}

/**
 * Called when a placement video related error occurs.
 * @param placement The TJPlacement that was sent
 * @param errorMessage Error message.
 */
- (void)videoDidFail:(TJPlacement *)placement
               error:(NSString *)errorMessage {
    [_delegate onInterstitialShowFail:_placementName
                     withErrorMessage:errorMessage];

}

/**
 * Called when a click event has occurred
 * @param placement The TJPlacement that was sent
 */
- (void)didClick:(TJPlacement*)placement {
    [_delegate onInterstitialDidClick:_placementName];
}

/**
 * Called when placement content did disappear
 * @param placement The TJPlacement that was sent
 */
- (void)contentDidDisappear:(TJPlacement *)placement {
    [_delegate onInterstitialDidClose:_placementName];
}

/**
 * Called when a placement video has completed playing.
 * @param placement The TJPlacement that was sent
 */
- (void)videoDidComplete:(TJPlacement *)placement {
}

/**
 * Called when placement content did appear
 * @param placement The TJPlacement that was sent
 */
- (void)contentDidAppear:(TJPlacement *)placement {
}

/**
 * Callback issued by TJ to publisher when the user has successfully completed a purchase request
 * @param placement - The TJPlacement that triggered the action request
 * @param request - The TJActionRequest object
 * @param productId - the id of the offer that sent the request
 */
- (void)placement:(TJPlacement *)placement
didRequestPurchase:(nullable TJActionRequest *)request
        productId:(nullable NSString *)productId {
    
}

/**
 * Callback issued by TJ to publisher when the user has successfully requests a reward
 * @param placement - The TJPlacement that triggered the action request
 * @param request   - The TJActionRequest object
 * @param itemId    - The itemId for whose reward has been requested
 * @param quantity  - The quantity of the reward for the requested itemId
 */
- (void)placement:(TJPlacement *)placement
 didRequestReward:(nullable TJActionRequest *)request
           itemId:(nullable NSString *)itemId
         quantity:(int)quantity {
    
}

@end
