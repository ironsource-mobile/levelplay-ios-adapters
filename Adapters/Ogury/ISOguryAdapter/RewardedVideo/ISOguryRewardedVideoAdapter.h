#import <Foundation/Foundation.h>
#import "ISOguryAdapter+Internal.h"

@interface ISOguryRewardedVideoAdapter : ISBaseRewardedVideoAdapter

- (instancetype)initWithOguryAdapter:(ISOguryAdapter *)adapter;
- (AdState)getAdState;
- (void)setAdState:(AdState)newState;

@end
