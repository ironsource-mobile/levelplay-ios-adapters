//
//  ISInterstitialCustomInterstitial.m
//  ISCustomAdapter
//
//  Created by Bar David on 03/11/2021.
//

#import "ISMockObjectiveCCustomInterstitial.h"
#import "ISMockObjectiveCCustomAdapter.h"
#import "ISMockCustomNetworkSdk.h"
#import "IronSource/ISLog.h"

@interface ISMockObjectiveCCustomInterstitial() <ISMockCustomNetworkInterstitialAdDelegate>

/**
 * Here you should declare the variables needed to
 * operate ad instance and return all callbacks successfully.
 * In this example we only need the delegate.
 */
@property(nonatomic, weak) id<ISInterstitialAdDelegate> adDelegate;
@property(nonatomic, strong) NSString* instanceData;

@end

@implementation ISMockObjectiveCCustomInterstitial

/**
 * You should declare the keys needed for the sdk instance level here
 * and access the data through the AdData class when needed.
 */
static NSString * const kSampleInstanceLevelKey = @"instance_level_key";

# pragma mark - IronSource ad lifecycle methods

   /**
    * This method will be called once the mediation tries to load your instance.
    * Here you should attempt to load you ad instance and make
    * sure to return the load result callbacks to the ad delegate.
    * @param adData the data for the current ad
    * @param delegate the ad delegate to return lifecycle callbacks
    */


- (void)loadAdWithAdData:(nonnull ISAdData *)adData
                delegate:(nonnull id<ISInterstitialAdDelegate>)delegate {
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

    // load interstitial ad
    LogAdapterApi_Internal(@"load ad with %@", _instanceData);
    
    [[ISMockCustomNetworkSdk sharedInstance] loadInterstitialAdWithInstanceData:_instanceData adDelegate:self];
}

/**
 * This method will be called once the mediation tries to show your instance.
 * Here you should attempt to show your ad instance
 * and return the lifecycle callbacks to the ad delegate.
 * @param adData the data for the current ad
 * @param delegate the ad interaction delegate to return lifecycle callbacks
*/
- (void)showAdWithViewController:(nonnull UIViewController *)viewController adData:(nonnull ISAdData *)adData delegate:(nonnull id<ISInterstitialAdDelegate>)delegate {
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
    
    // show interstitial ad
    LogAdapterApi_Internal(@"instanceId = %@", instanceData);
    [[ISMockCustomNetworkSdk sharedInstance] showInterstitialAdWithInstanceData:instanceData adDelegate:self];
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

# pragma mark - CustomNetworkInterstitialAdDelegate callbacks

// Indicates that interstitial ad was loaded successfully
- (void)adLoaded {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidLoad];
}

// The interstitial ad failed to load. Use ironSource ErrorTypes (No Fill / Other)
- (void)adLoadFailedWithErrorCode:(NSInteger)errorCode
                      errorMessage:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"error = %ld, message = %@",(long)errorCode, errorMessage);

    // error type should represent the error you received
    // when the error is due to no fill you should specify it
    ISAdapterErrorType error = [[ISMockCustomNetworkSdk sharedInstance] isErrorNoFillWithErrorCode:errorCode] ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    
    // return callback
    [_adDelegate adDidFailToLoadWithErrorType:error errorCode:errorCode errorMessage:errorMessage];
}

// Indicates the network differentiates between show-success and ad-open (impression)
- (void)adShowSucceed {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidShowSucceed];
}

// The ad could not be displayed
- (void)adShowFailedWithErrorCode:(NSInteger)errorCode errorMessage:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"error = %ld, message = %@", (long)errorCode, errorMessage);
    [_adDelegate adDidFailToShowWithErrorCode:errorCode errorMessage:errorMessage];
}

// The interstitial ad was displayed successfully to the user. This indicates an impression.
- (void)adOpened {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidOpen];
}

// User closed the interstitial ad
- (void)adClosed {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidClose];
}

// Indicates an ad was clicked
- (void)adClicked {
    LogAdapterDelegate_Internal(@"instanceId = %@", _instanceData);
    [_adDelegate adDidClick];
}

@end
