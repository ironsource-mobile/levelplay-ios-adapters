//
//  ISBigoBannerDelegate.h
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BigoADS/BigoBannerAdLoader.h>

@protocol ISBannerAdDelegate;
@class ISBigoBannerAdapter;
@class BigoBannerAd;

@interface ISBigoBannerDelegate : NSObject <BigoBannerAdLoaderDelegate, BigoAdInteractionDelegate>

@property (nonatomic, weak) ISBigoBannerAdapter     *adapter;
@property (nonatomic, weak) id<ISBannerAdDelegate>  delegate;

- (instancetype)initWithAdapter:(ISBigoBannerAdapter *)adapter
                       delegate:(id<ISBannerAdDelegate>)delegate;

@end
