//
//  ISYSOInterstitialAdDelegate.h
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YsoNetwork/YsoNetwork.h>
#import <YsoNetwork/YsoNetwork-Swift.h>
#import <IronSource/ISBaseAdapter+Internal.h>

@interface ISYSOInterstitialAdDelegate : NSObject

@property (nonatomic, strong) NSString* placementKey;
@property (nonatomic, weak) ISYSOAdapter *adapter;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> delegate;

- (instancetype)initWithPlacementKey:(NSString *)placementKey
                            adapter:(ISYSOAdapter *)adapter
                        andDelegate:(id<ISInterstitialAdapterDelegate>)delegate;

- (void)handleOnLoad:(e_ActionError)error;
- (void)handleOnDisplay:(YNWebView *)view;
- (void)handleOnClick;
- (void)handleOnClose:(BOOL)display complete:(BOOL)complete;

@end
