#pragma once

#include <UIKit/UIKit.h>
#include "./GLAdsSDKTypes.h"

@protocol GLAdsSDKDelegate <NSObject>
@required
-(void) AdWasLoaded:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
-(void) AdLoadFailed:(GLAdsSDK_AdType)adType instance:(NSString*)instance reason:(GLAdsSDK_AdLoadFailedReason)reason;
-(void) AdHasExpired:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
-(void) AdWillShow:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
-(void) AdShowFailed:(GLAdsSDK_AdType)adType instance:(NSString*)instance reason:(GLAdsSDK_AdShowFailedReason)reason;
-(void) AdClicked:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
-(void) AdRewarded:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
-(void) AdWasClosed:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
@end

@interface GLAdsSDK : NSObject
@property (class, nonatomic, readonly) NSInteger VersionMajor;
@property (class, nonatomic, readonly) NSInteger VersionMinor;
@property (class, nonatomic, readonly) NSInteger VersionPatch;
@property (class, nonatomic, readonly) NSString* VersionString;

+(void) SetParentViewController:(UIViewController*)parentViewController;
+(void) InitializeWithDelegate:(id <GLAdsSDKDelegate>)theDelegate;
+(BOOL) IsInitialized;
+(void) LoadAd:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
+(void) ShowLoadedAd:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
+(BOOL) IsAdLoaded:(GLAdsSDK_AdType)adType instance:(NSString*)instance;
+(void) HideAd:(GLAdsSDK_AdType)adType;
+(void) SetBannerPosition:(int)xOffset yOffset:(int)yOffset align:(GLAdsSDK_AdAlign)align;
+(void) SetTestMode:(BOOL)testMode;
+(void) Pause;
+(void) Resume;
+(void) Close;

@end
