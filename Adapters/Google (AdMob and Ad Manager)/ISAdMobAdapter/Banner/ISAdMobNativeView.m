//
//  ISAdMobNativeView.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
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
@property (strong, nonatomic) ISAdMobNativeBannerTemplate *nativeTemplate;

@end

@implementation ISAdMobNativeView

static CGFloat const BorderWidth = 1.0;
static CGFloat const CornerRadius = 5;

@synthesize nativeAd;

- (instancetype _Nonnull) initWithTemplate:(nonnull ISAdMobNativeBannerTemplate *)template
                                  nativeAd:(nonnull GADNativeAd *)nativeAd {
    
    self = [super initWithFrame:template.frame];
    if (self) {
        self.nativeAd = nativeAd;
        self.nativeTemplate = template;
        [self setupUI];
        [self setupAdView];
        
        LogAdapterApi_Internal(
                               @"nativeAd template = %@, headline = %@, body = %@ , icon = %@, mediaContent = %@, mediaContent.hasVideoContent = %@, advertiser = %@, callToAction = %@",
                               template.nibName,
                               nativeAd.headline,
                               nativeAd.body,
                               nativeAd.icon.imageURL ? nativeAd.icon.imageURL : @"NO",
                               nativeAd.mediaContent ? @"YES" : @"NO",
                               nativeAd.mediaContent.hasVideoContent ? @"YES" : @"NO",
                               nativeAd.advertiser,
                               nativeAd.callToAction);
    }
    return self;
}

- (void) setupUI {
    NSString* path= [[NSBundle mainBundle] pathForResource:@"ISAdMobResources" ofType:@"bundle"];
    NSBundle* resourcesBundle = [NSBundle bundleWithPath:path];
    [resourcesBundle loadNibNamed:self.nativeTemplate.nibName owner:self options:nil];
    
    self.nativeAdView.translatesAutoresizingMaskIntoConstraints = YES;
    [self addSubview:self.nativeAdView];
    self.nativeAdView.frame = self.bounds;
}

- (void)setupAdView {
    
    [self setupBorder];
    [self setupAdBadge];
    [self setupIconView];
    [self setupHeadlineView];
    [self setupAdvertiserView];
    [self setupBodyView];
    [self setupMediaView];
    [self setupCallToAction];
    self.nativeAdView.nativeAd = self.nativeAd;
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

- (void) setupMediaView {
    
    BOOL shouldHideMedia = self.nativeAd.mediaContent.hasVideoContent && self.nativeTemplate.hideVideoContent;
    
    self.nativeAdView.mediaView = self.media;
    self.nativeAdView.mediaView.mediaContent = self.nativeAd.mediaContent;
    self.media.hidden = self.nativeAd.mediaContent ? shouldHideMedia : YES;
}

- (void) setupCallToAction {
    
    self.nativeAdView.callToActionView = self.callToAction;
    [self.callToAction setTitle:self.nativeAd.callToAction
                       forState:UIControlStateNormal];
    self.callToAction.layer.cornerRadius = CornerRadius;
    self.callToAction.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 15);
    self.callToAction.clipsToBounds = YES;
    self.callToAction.userInteractionEnabled = NO;
    self.callToAction.hidden = self.nativeAd.callToAction ? self.nativeTemplate.hideCallToAction : NO;
}

- (GADNativeAdView *) getNativeAdView {
    return self.nativeAdView;
}

@end
