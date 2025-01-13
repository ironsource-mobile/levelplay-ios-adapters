//
//  ISAppLovinAdHolder.h
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ISAppLovinAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ISAppLovinAdHolder<__covariant V> : NSObject

- (void)storeAd:(V)value forKey:(ISAppLovinAdapter *)key;

- (nullable V)retrieveAdForKey:(ISAppLovinAdapter *)key;

- (void)removeAdForKey:(ISAppLovinAdapter *)key;

- (NSArray<ISAppLovinAdapter *> *)getAdapters;

@end

NS_ASSUME_NONNULL_END
