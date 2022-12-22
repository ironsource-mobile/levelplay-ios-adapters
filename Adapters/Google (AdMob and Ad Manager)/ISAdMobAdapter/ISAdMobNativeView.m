//
//  ISAdMobNativeView.m
//  ISAdMobAdapter
//
//  Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import "ISAdMobNativeView.h"

@interface ISAdMobNativeView ()

@property (weak, nonatomic) IBOutlet UILabel *adBadge;
@property (weak, nonatomic) IBOutlet UILabel *headline;
@property (weak, nonatomic) IBOutlet GADMediaView *media;
@property (weak, nonatomic) IBOutlet UILabel *body;
@property (weak, nonatomic) IBOutlet UILabel *advertiser;
@property (weak, nonatomic) IBOutlet UIButton *callToAction;
@property (weak, nonatomic) IBOutlet UIImageView *icon;

@property (strong, nonatomic) IBOutlet GADNativeAdView *nativeAdView;
@property (strong, nonatomic) GADNativeAd *nativeAd;

@end

@implementation ISAdMobNativeView

static CGFloat const BorderWidth = 1.0;
static CGFloat const CornerRadius = 5;

@synthesize nativeAd;

- (instancetype) initWithLayout:(ISAdMobNativeViewLayout *)layout
                       nativeAd:(GADNativeAd *)nativeAd {
    
    self = [super initWithFrame:layout.frame];
    if (self) {
        self.nativeAd = nativeAd;
        [self setupUI:layout.nibName];
        [self setupAdView:layout];
        self.nativeAdView.nativeAd = nativeAd;
    }
    return self;
}

- (void) setupUI:(NSString *)nibName {
    NSString* path= [[NSBundle mainBundle] pathForResource:@"ISAdMobResources" ofType:@"bundle"];
    NSBundle* resourcesBundle = [NSBundle bundleWithPath:path];
    [resourcesBundle loadNibNamed:nibName owner:self options:nil];
    
    self.nativeAdView.translatesAutoresizingMaskIntoConstraints = YES;
    [self addSubview:self.nativeAdView];
    self.nativeAdView.frame = self.bounds;
}

- (void)setupAdView:(ISAdMobNativeViewLayout *)layout {
    
    [self setupBorder];
    [self setupAdBadge];
    [self setupIconView];
    [self setupHeadlineView];
    [self setupAdvertiserView];
    [self setupBodyView];
    [self setupMediaView:layout.shouldHideVideoContent];
    [self setupCallToAction:layout.shouldHideCallToAction];
}

- (void) setupBorder {
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = BorderWidth;
}

- (void) setupAdBadge {
    
    self.adBadge.layer.borderColor = self.adBadge.textColor.CGColor;
    self.adBadge.layer.borderWidth = BorderWidth;
    self.adBadge.layer.cornerRadius = CornerRadius;
    self.adBadge.clipsToBounds = YES;
}

- (void) setupIconView {
    
    self.nativeAdView.iconView = self.icon;
    self.icon.layer.cornerRadius = CornerRadius;
    self.icon.clipsToBounds = YES;
    self.icon.image = self.nativeAd.icon.image;
    self.icon.hidden = self.nativeAd.icon ? NO : YES;
}

- (void) setupHeadlineView {
    
    self.nativeAdView.headlineView = self.headline;
    self.headline.text = self.nativeAd.headline;
    self.headline.hidden = self.nativeAd.headline ? NO : YES;
}

- (void) setupAdvertiserView {
    
    self.nativeAdView.advertiserView = self.advertiser;
    self.advertiser.text = self.nativeAd.advertiser;
    self.advertiser.hidden = self.nativeAd.advertiser ? NO : YES;
}

- (void) setupBodyView {
    
    self.nativeAdView.bodyView = self.body;
    self.body.text = self.nativeAd.body;
    self.body.hidden = self.nativeAd.body ? NO : YES;
}

- (void) setupMediaView:(BOOL)shouldHideVideoContent {
    
    BOOL shouldHideMedia = self.nativeAd.mediaContent.hasVideoContent && shouldHideVideoContent;
    
    self.nativeAdView.mediaView = self.media;
    self.nativeAdView.mediaView.mediaContent = self.nativeAd.mediaContent;
    self.media.hidden = self.nativeAd.mediaContent ? shouldHideMedia : YES;
}

- (void) setupCallToAction:(BOOL)shouldHideCallToAction {
    
    self.nativeAdView.callToActionView = self.callToAction;
    [self.callToAction setTitle:self.nativeAd.callToAction
                       forState:UIControlStateNormal];
    self.callToAction.layer.cornerRadius = CornerRadius;
    self.callToAction.clipsToBounds = YES;
    self.callToAction.userInteractionEnabled = NO;
    self.callToAction.hidden = self.nativeAd.callToAction ? shouldHideCallToAction : NO;
}
- (GADNativeAdView *) getNativeAdView {
    return self.nativeAdView;
}

@end
