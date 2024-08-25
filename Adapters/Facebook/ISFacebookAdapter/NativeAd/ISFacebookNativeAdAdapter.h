//
//  ISFacebookNativeAdAdapter.h
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ISFacebookAdapter.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface ISFacebookNativeAdAdapter : ISBaseNativeAdAdapter

- (instancetype)initWithFacebookAdapter:(ISFacebookAdapter *)adapter;

@end
