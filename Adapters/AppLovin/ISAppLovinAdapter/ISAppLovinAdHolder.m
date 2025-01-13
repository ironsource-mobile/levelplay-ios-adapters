//
//  ISAppLovinAdHolder.m
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISAppLovinAdHolder.h"
#import <ISAppLovinAdapter.h>

@implementation ISAppLovinAdHolder {
    NSMapTable<ISAppLovinAdapter *, id> *mapTable;
    NSObject *syncObject;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        mapTable = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)storeAd:(id)value forKey:(ISAppLovinAdapter *)key {
    @synchronized (syncObject) {
        [mapTable setObject:value forKey:key];
    }
}

- (nullable id)retrieveAdForKey:(ISAppLovinAdapter *)key {
    @synchronized (syncObject) {
        id object = [mapTable objectForKey:key];
        return object;
    }
}

- (void)removeAdForKey:(ISAppLovinAdapter *)key {
    @synchronized (syncObject) {
        [mapTable removeObjectForKey:key];
    }
}

- (NSArray<ISAppLovinAdapter *> *)getAdapters {
    NSArray<ISAppLovinAdapter *> *keys = [[mapTable keyEnumerator] allObjects];
    return keys;
}

@end
