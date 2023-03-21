//
//  ISAdMobNativeViewLayout.h
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ISAdMobNativeViewLayout : NSObject

@property(assign, nonatomic) BOOL shouldHideCallToAction;
@property(assign, nonatomic) BOOL shouldHideVideoContent;
@property(assign, nonatomic) CGRect frame;
@property(assign, nonatomic) NSString* nibName;

- (instancetype) initWithSize:(NSString *)size;

@end
