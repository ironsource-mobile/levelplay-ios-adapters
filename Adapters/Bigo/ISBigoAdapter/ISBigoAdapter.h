//
//  ISBigoAdapter.h
//  ISBigoAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>

static NSString * const BigoAdapterVersion = @"4.3.4";
static NSString * Githash = @"";

@interface ISBigoAdapter : ISBaseAdapter

@property (nonatomic, strong, readonly) NSString *mediationInfo;

- (NSString *)getMediationInfo;

@end
