//
//  ISAppLovinAdapter+Internal.h
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAppLovinAdapter.h"
#import "ISAppLovinConstants.h"
#import <IronSource/ISAdapterErrors.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface ISAppLovinAdapter ()

+ (NSString *)errorMessageForCode:(int)code;

@end
