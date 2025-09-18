//
//  ISBigoAdapter.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IronSource/ISBaseAdapter+Internal.h>
#import <IronSource/IronSource.h>

static NSString * const BigoAdapterVersion = @"5.0.0";
static NSString * Githash = @"";

@interface ISBigoAdapter : ISBaseAdapter

@property (nonatomic, strong, readonly) NSString *mediationInfo;

- (NSString *)getMediationInfo;
@end
