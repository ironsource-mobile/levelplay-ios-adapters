//
//  ISAdMobNativeViewLayout.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISAdMobNativeViewLayout.h>

@interface ISAdMobNativeViewLayout ()
@end

static NSString* const SmallTemplate = @"ISAdMobNativeBannerSmallView";
static NSString* const MediumTemplate = @"ISAdMobNativeBannerMediumView";

@implementation ISAdMobNativeViewLayout

- (instancetype) initWithSize:(NSString *)size {
    
    self = [super init];
    if (self) {
        self.nibName = SmallTemplate;
        self.frame = CGRectZero;
        self.shouldHideCallToAction = false;
        self.shouldHideVideoContent = true;

        if ([size isEqualToString:@"BANNER"] ||
            [size isEqualToString:@"SMART"]) {
            self.frame = CGRectMake(0, 0,320, 50);
            self.shouldHideCallToAction = true;
        } else if ([size isEqualToString:@"LARGE"]) {
            self.frame = CGRectMake(0, 0,320, 90);
        } else if ([size isEqualToString:@"RECTANGLE"]) {
            self.nibName = MediumTemplate;
            self.frame = CGRectMake(0, 0,300, 250);
            self.shouldHideVideoContent = false;
        }
    }
    return self;
}

@end
