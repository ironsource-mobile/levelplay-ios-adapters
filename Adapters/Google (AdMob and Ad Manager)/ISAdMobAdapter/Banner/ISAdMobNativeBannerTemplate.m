//
//  ISAdMobNativeBannerTemplate.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISAdMobNativeBannerTemplate.h>

@interface ISAdMobNativeBannerTemplate ()
@end

static NSString * const NativeTemplateName = @"nativeBannerTemplateName";

static NSString * const NativeTemplateBasicName = @"NB_TMP_BASIC";
static NSString * const NativeTemplateTextCTAName = @"NB_TMP_TEXT_CTA";

@implementation ISAdMobNativeBannerTemplate

- (instancetype)initWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                      sizeDescription:(NSString *)sizeDescription {
    
    self = [super init];
    if (self) {
        if ([sizeDescription isEqualToString:@"BANNER"] ||
            [sizeDescription isEqualToString:@"SMART"]) {
            
            NSString *templateName = adapterConfig.settings[NativeTemplateName];
            if ([templateName isEqualToString:NativeTemplateBasicName]) {
                [self initBasicTemplate];
            } else if ([templateName isEqualToString:NativeTemplateTextCTAName]) {
                [self initTextCTATemplate];
            } else {
                [self initIconTextTemplate];
            }
        } else if ([sizeDescription isEqualToString:@"LARGE"]) {
            [self initBasicLargeTemplate];
        } else if ([sizeDescription isEqualToString:@"RECTANGLE"]) {
            [self initRectTemplate];
        } else {
            [self initBasicTemplate];
        }
    }
    return self;
}

- (void)initWithNibName:(NSString *)nibName
       hideCallToAction:(BOOL)hideCallToAction
       hideVideoContent:(BOOL)hideVideoContent
      adChoicesPosition:(GADAdChoicesPosition)adChoicesPosition
       mediaAspectRatio:(GADMediaAspectRatio)mediaAspectRatio
                   size:(CGSize)size {
    
    self.nibName = nibName;
    self.hideCallToAction = hideCallToAction;
    self.hideVideoContent = hideVideoContent;
    self.adChoicesPosition = adChoicesPosition;
    self.mediaAspectRatio = mediaAspectRatio;
    self.frame = CGRectMake(0, 0, size.width, size.height);
}

- (void)initBasicTemplate {
    [self initWithNibName:@"ISAdMobNativeBannerTemplateBasicView"
         hideCallToAction:YES
         hideVideoContent:YES
        adChoicesPosition:GADAdChoicesPositionTopRightCorner
         mediaAspectRatio:GADMediaAspectRatioAny
                     size:GADAdSizeBanner.size];
}

- (void)initBasicLargeTemplate {
    [self initWithNibName:@"ISAdMobNativeBannerTemplateBasicView"
         hideCallToAction:NO
         hideVideoContent:YES
        adChoicesPosition:GADAdChoicesPositionTopRightCorner
         mediaAspectRatio:GADMediaAspectRatioSquare
                     size:GADAdSizeLargeBanner.size];
}

- (void)initIconTextTemplate {
    [self initWithNibName:@"ISAdMobNativeBannerTemplateIconTextView"
         hideCallToAction:YES
         hideVideoContent:NO
        adChoicesPosition:GADAdChoicesPositionTopRightCorner
         mediaAspectRatio:GADMediaAspectRatioAny
                     size:GADAdSizeBanner.size];
}

- (void)initTextCTATemplate {
    [self initWithNibName:@"ISAdMobNativeBannerTemplateTextCTAView"
         hideCallToAction:NO
         hideVideoContent:NO
        adChoicesPosition:GADAdChoicesPositionBottomLeftCorner
         mediaAspectRatio:GADMediaAspectRatioAny
                     size:GADAdSizeBanner.size];
}

- (void)initRectTemplate {
    [self initWithNibName:@"ISAdMobNativeBannerTemplateRectView"
         hideCallToAction:NO
         hideVideoContent:NO
        adChoicesPosition:GADAdChoicesPositionTopRightCorner
         mediaAspectRatio:GADMediaAspectRatioLandscape
                     size:GADAdSizeMediumRectangle.size];
}

@end
