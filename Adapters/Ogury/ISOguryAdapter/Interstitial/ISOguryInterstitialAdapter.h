#import <Foundation/Foundation.h>
#import "ISOguryAdapter+Internal.h"
#import "ISOguryAdapter+Internal.h"

@interface ISOguryInterstitialAdapter : ISBaseInterstitialAdapter

- (instancetype)initWithOguryAdapter:(ISOguryAdapter *)adapter;
- (AdState)getAdState;
- (void)setAdState:(AdState)newState;

@end
