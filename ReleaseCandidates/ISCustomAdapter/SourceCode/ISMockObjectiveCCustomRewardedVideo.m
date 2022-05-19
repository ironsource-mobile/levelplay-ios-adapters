//
//  ISCustomRewardedVideo.m
//  ISCustomAdapter
//
//  Created by Bar David on 04/11/2021.
//

#import "ISMockObjectiveCCustomRewardedVideo.h"
#import "ISMockObjectiveCCustomAdapter.h"
#import "ISMockCustomNetworkSdk.h"
#import "IronSource/ISLog.h"

@interface ISMockObjectiveCCustomRewardedVideo() <ISMockCustomNetworkRewardedVideoAdDelegate>

/**
 * Here you should declare the variables needed to
 * operate ad instance and return all callbacks successfully.
 * In this example we only need the delegate.
 */
@property(nonatomic, weak) id<ISRewardedVideoAdDelegate> adDelegate;
@property(nonatomic, strong) NSString* instanceData;

@end

@implementation ISMockObjectiveCCustomRewardedVideo

static NSString * const kSampleInstanceLevelKey = @"instance_level_key";

/**
 * This method will be called once the mediation tries to load your instance.
 * Here you should attempt to load you ad instance and make
 * sure to return the load result callbacks to the ad delegate.
 * @param adData the data for the current ad
 * @param delegate the ad delegate to return lifecycle callbacks
 */


- (void)loadAdWithAdData:(nonnull ISAdData *)adData
                delegate:(nonnull id<ISRewardedVideoAdDelegate>)delegate {
    // save delegate
    _adDelegate = delegate;
    
    // retrieve your instance level configuration
    _instanceData = adData.configuration[kSampleInstanceLevelKey];
    
    // validate the data needed and if data is not valid return load failed
    if (_instanceData.length == 0) {
        
        // return load failed with error code for missing params and a message stating which parameter is invalid
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:[NSString stringWithFormat:@"missing value for key %@", kSampleInstanceLevelKey]];
        return;
    }
    // example of data retrieved from your network adapter
    // optional when this data is required
    ISMockObjectiveCCustomAdapter *networkAdapter = nil;
    id<ISAdapterBaseProtocol> adapter = [self getNetworkAdapter];
    if ([adapter isKindOfClass:[ISMockObjectiveCCustomAdapter class]]) {
        networkAdapter = (ISMockObjectiveCCustomAdapter*) adapter;
    }
    
    if (networkAdapter == nil) {
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:@"missing network adapter"];
        return;
    }
    
    // call network level method
    NSString *extraData = [networkAdapter sampleAppLevelData];
    [[ISMockCustomNetworkSdk sharedInstance] setExtraData:extraData];
    
    // load rewarded video ad
    LogAdapterApi_Internal(@"instanceId = %@", _instanceData);
    [[ISMockCustomNetworkSdk sharedInstance] loadRewardedVideoAdWithInstanceData:_instanceData adDelegate:self];
}

/**
 * This method will be called once the mediation tries to show your instance.
 * Here you should attempt to show your ad instance
 * and return the lifecycle callbacks to the ad delegate.
 * @param adData the data for the current ad
 * @param delegate the ad interaction delegate to return lifecycle callbacks
 */
- (void)showAdWithViewController:(nonnull UIViewController *)viewController adData:(nonnull ISAdData *)adData delegate:(nonnull id<ISRewardedVideoAdDelegate>)delegate {
    // save delegate
    _adDelegate = delegate;
    
    // retrieve your instance level configuration
    NSString *instanceData = adData.configuration[kSampleInstanceLevelKey];
    
    // verify you have an ad to show for this configuration
    // if not return show failed
    if (![[ISMockCustomNetworkSdk sharedInstance] isAdReadyWithInstanceData:instanceData]) {
        // return show failed callback
        [delegate adDidFailToShowWithErrorCode:ISAdapterErrorInternal errorMessage:@"ad is not ready to show for the current instanceData"];
        return;
    }
    
    // show rewarded video ad
    LogAdapterApi_Internal(@"instanceId = %@", instanceData);
    [[ISMockCustomNetworkSdk sharedInstance] showRewardedVideoAdWithInstanceData:instanceData adDelegate:self];
}

/**
 * This method should indicate if you have an ad ready to show for the this adData configurations
 * @param adData the data for the current ad
 * @return true if you have an ad ready and false if not
 */
- (BOOL)isAdAvailableWithAdData:(nonnull ISAdData *)adData { 
    // retrieve your instance level configuration
    NSString *instanceData = adData.configuration[kSampleInstanceLevelKey];
    
    // validate the data needed and if data is not valid return show failed
    return
    instanceData.length != 0 &&
    [[ISMockCustomNetworkSdk sharedInstance] isAdReadyWithInstanceData:instanceData];
}

# pragma mark - CustomNetworkRewardedVideoAdDelegate callbacks

// Indicates that rewarded video ad was loaded successfully
- (void)adLoaded {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidLoad];
}

// The rewarded video ad failed to load. Use ironSource ErrorTypes (No Fill / Other)
- (void)adLoadFailedWithErrorCode:(NSInteger)errorCode
                      errorMessage:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"error = %ld, message = %@", (long)errorCode, errorMessage);
    
    // error type should represent the error you received
    // when the error is due to no fill you should specify it
    ISAdapterErrorType errorType = [[ISMockCustomNetworkSdk sharedInstance] isErrorNoFillWithErrorCode:errorCode] ? ISAdapterErrorTypeNoFill :
    [[ISMockCustomNetworkSdk sharedInstance] isErrorExpiredWithErrorCode:errorCode] ? ISAdapterErrorTypeAdExpired :
    ISAdapterErrorTypeInternal;
    
    // return callback
    [_adDelegate adDidFailToLoadWithErrorType:errorType errorCode:errorCode errorMessage:errorMessage];
}

// The ad could not be displayed
- (void)adShowFailedWithErrorCode:(NSInteger)errorCode errorMessage:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"error = %lu, message = %@", (unsigned long)errorCode, errorMessage);
    [_adDelegate adDidFailToShowWithErrorCode:errorCode errorMessage:errorMessage];
}

// The rewarded video ad was displayed successfully to the user. This indicates an impression.
- (void)adOpened {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidOpen];
}

// User closed the rewarded video ad
- (void)adClosed {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidClose];
}

// Indicates an ad was clicked
- (void)adClicked {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidClick];
}

// Indicates the network differentiates between show-success and ad-open (impression)
-(void)adShowSucceed {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidShowSucceed];
}

-(void)adStarted {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidStart];
}

-(void)adEnded {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidEnd];
}

// User got a reward after watching the ad
- (void)adRewarded {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adRewarded];
}

-(void)adVisible {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidBecomeVisible];
}

@end
