//
//  ISXAppLovinInterstitialAdapter.m
//  ISApplovinAdapter
//
//  Created by Guy Lis on 28/04/2021.
//  Copyright © 2021 Supersonic. All rights reserved.
//

#import "ISXAppLovinCustomInterstitial.h"
#import "ISXAppLovinCustomAdapter.h"
//#import "ALInterstitialAd.h"
#import "IronSource/ISLog.h"


@interface ISXAppLovinCustomInterstitial()
//<ALAdDisplayDelegate, ALAdLoadDelegate>


//@property(nonatomic, strong) ALInterstitialAd* ad;
//@property(nonatomic, strong) ALAd* renderedAd;
@property(nonatomic, strong) NSString* zoneId;
@property(nonatomic, strong) NSObject * delegate;



@end


@implementation ISXAppLovinCustomInterstitial

//static NSString * const NO_ZONE_ID      = @"NO_ZONE_ID";
//
//// TODO add ctor initializing values to nil
//
//
//#pragma mark - API methods
//
//- (void) loadAdWithAdData:(NSObject *) adData
//    adapterAdDelegate:(NSObject *) delegate {
//
//    __weak typeof(self) wself = self;
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        __strong typeof(wself) self = wself; // TODO check if weak/strong is needed here
//
//        NSString *zoneId = @""; // TODO update retrieval
//        ISXAppLovinCustomAdapter *networkAdapter; // TODO retrieve network adapter
//
//        if (networkAdapter == nil || networkAdapter.appLovinSDK == nil) {
////            [_delegate didFailToLoadWithLoadErrorType:LoadErrorType.INTERNAL
////                                            errorCode: 1 errorMessage: @""];
//        }
////        _ad = [[ALInterstitialAd alloc] initWithSdk:networkAdapter.appLovinSDK];
////        _ad.adDisplayDelegate = self;
////        _ad.adLoadDelegate = self;
//        LogAdapterApi_Info(@"load ad zoneId=%@", zoneId);
//        if ([zoneId isEqualToString:NO_ZONE_ID]) {
//            [[networkAdapter.appLovinSDK adService] loadNextAd:ALAdSize.interstitial andNotify:self];
//        }
//        else {
//            [[networkAdapter.appLovinSDK adService] loadNextAdForZoneIdentifier:zoneId andNotify:self];
//        }
//
//    });
//
//
//}
//
//- (BOOL) isAdAvailableWithAdData:(NSObject *) adData {
//    return _renderedAd != nil;
//}
//
//
//- (void) showAdWithAdData:(NSObject *) adData
//           viewController:(UIViewController *)viewController{
//
//    if (_ad == nil || _renderedAd == nil || viewController == nil) {
//        LogAdapterApi_Internal(@"ad == nil || renderedAd == nil || viewController == nil");
//        //    [_delegate didShowFailWithError:error];
//        return;
//    }
//
//    [_ad showAd:_renderedAd];
//
//}
//
//#pragma mark - ALAdDisplayDelegate methods
//
//- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
//    LogAdapterDelegate_Internal(@"zoneId = %@", ad.zoneIdentifier);
////    [_delegate didAdClick];
//}
//
//- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
//    LogAdapterDelegate_Internal(@"zoneId = %@", ad.zoneIdentifier);
//    //    [_delegate didAdOpen];
//
//}
//
//- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
//    LogAdapterDelegate_Internal(@"zoneId = %@", ad.zoneIdentifier);
//    //    [_delegate didAdClose];
//
//}
//
//
//#pragma mark - ALAdLoadDelegate methods
//
//- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
//    LogAdapterDelegate_Internal(@"zoneId = %@", _zoneId);
//
////    [_delegate didFailToLoadWithLoadErrorType:
////     code == kALErrorCodeNoFill ? LoadErrorType.NO_FILL : LoadErrorType.INTERNAL]
////     errorCode code errorMessage [@""];
//
//
//}
//
//- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
//    LogAdapterDelegate_Internal(@"zoneId = %@", _zoneId);
//    _renderedAd = ad;
////    [_delegate didAdLoad];
//
//
//}
//
//#pragma mark - helper methods
//
//- (NSString *)getErrorMessage:(int)code {
//    NSString *errorCode = @"Unknown error";
//    switch (code) {
//        case kALErrorCodeSdkDisabled:
//            errorCode = @"The SDK is currently disabled.";
//            break;
//        case kALErrorCodeNoFill:
//            errorCode = @"No ads are currently eligible for your device & location.";
//            break;
//        case kALErrorCodeAdRequestNetworkTimeout:
//            errorCode = @"A fetch ad request timed out (usually due to poor connectivity).";
//            break;
//        case kALErrorCodeNotConnectedToInternet:
//            errorCode = @"The device is not connected to internet (for instance if user is in Airplane mode).";
//            break;
//        case kALErrorCodeAdRequestUnspecifiedError:
//            errorCode = @"An unspecified network issue occured.";
//            break;
//        case kALErrorCodeUnableToRenderAd:
//            errorCode = @"There has been a failure to render an ad on screen.";
//            break;
//        case kALErrorCodeInvalidZone:
//            errorCode = @"The zone provided is invalid; the zone needs to be added to your AppLovin account or may still be propagating to our servers.";
//            break;
//        case kALErrorCodeInvalidAdToken:
//            errorCode = @"The provided ad token is invalid; ad token must be returned from AppLovin S2S integration.";
//            break;
//        case kALErrorCodeUnableToPrecacheResources:
//            errorCode = @"An attempt to cache a resource to the filesystem failed; the device may be out of space.";
//            break;
//        case kALErrorCodeUnableToPrecacheImageResources:
//            errorCode = @"An attempt to cache an image resource to the filesystem failed; the device may be out of space.";
//            break;
//        case kALErrorCodeUnableToPrecacheVideoResources:
//            errorCode = @"An attempt to cache a video resource to the filesystem failed; the device may be out of space.";
//            break;
//        case kALErrorCodeInvalidResponse:
//            errorCode = @"The AppLovin servers have returned an invalid response.";
//            break;
//        case kALErrorCodeIncentiviziedAdNotPreloaded:
//            errorCode = @"The developer called for a rewarded video before one was available.";
//            break;
//        case kALErrorCodeIncentivizedUnknownServerError:
//            errorCode = @"An unknown server-side error occurred.";
//            break;
//        case kALErrorCodeIncentivizedValidationNetworkTimeout:
//            errorCode = @"A reward validation requested timed out (usually due to poor connectivity)";
//            break;
//        case kALErrorCodeIncentivizedUserClosedVideo:
//            errorCode = @"The user exited out of the video early. You may or may not wish to grant a reward depending on your preference.";
//            break;
//        case kALErrorCodeInvalidURL:
//            errorCode = @"A postback URL you attempted to dispatch was empty or nil.";
//            break;
//        default:
//            errorCode = [NSString stringWithFormat:@"Unknown error code %d", code];
//            break;
//    }
//
//    return errorCode;
//}

@end
