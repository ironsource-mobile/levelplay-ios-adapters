//
//  ISXAppLovinNetworkAdapter.m
//  ISApplovinAdapter
//
//  Created by Guy Lis on 28/04/2021.
//  Copyright © 2021 Supersonic. All rights reserved.
//

#import "ISXAppLovinCustomAdapter.h"
#import "IronSource/ISLog.h"

@interface ISXAppLovinCustomAdapter()


//@property(nonatomic, assign) BOOL adapterDebug;


@end

@implementation ISXAppLovinCustomAdapter

//static NSString *const kSdkKeyField = @"sdkKey";
//static NSString *const kAdapterVersion = @"4.3.23";
//
//
//#pragma mark - API methods
//
//// TODO update signature
//- (void) initWithAdData:(NSObject *) adData
//    adapterInitDelegate:(NSObject *) delegate {
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//                    
//            NSString *sdkKey = @""; // TODO update retrieval
//            NSString *userId = @""; // TODO update retrieval
//            
//            
//            if (sdkKey.length == 0) {
//                NSString *error = [NSString stringWithFormat:@"error - missing param = %@", kSdkKeyField];
//                LogInternal_Error(@"%@", error);
//    //            [delegate initDidFailWithErrorCode:1 errorMessage:error];// TODO update once object is ready
//            }
//        
//            _appLovinSDK = [ALSdk sharedWithKey:sdkKey];
//            _appLovinSDK.settings.isVerboseLogging = _adapterDebug;
//            if (userId.length > 0) {
//                LogAdapterApi_Internal(@"set userID to %@", userId);
//                _appLovinSDK.userIdentifier = userId;
//            }
//            LogAdapterApi_Info(@"sdkKey=%@, isVerboseLogging=%d", sdkKey, _appLovinSDK.settings.isVerboseLogging);
//        });
//
//    //    [delegate initDidSucceed] // TODO update once object is ready
//
//    });
//}
//
//- (NSString *) networkSDKVersion {
//    return [ALSdk version];
//}
//
//- (NSString *) adapterVersion {
//    return kAdapterVersion;
//}
//
//       
//#pragma mark - ISAdapterDebugInterface methods
//
//- (void) setAdapterDebug:(BOOL) adapterDebug {
//    _adapterDebug = adapterDebug;
//}

@end
