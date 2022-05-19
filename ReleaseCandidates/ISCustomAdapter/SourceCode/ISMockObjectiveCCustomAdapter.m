//
//  ISCustomAdapter.m
//  ISCustomAdapter
//
//  Created by Bar David on 01/11/2021.
//

#import "ISMockObjectiveCCustomAdapter.h"
#import "ISMockCustomNetworkSdk.h"
#import "IronSource/ISLog.h"

@interface ISMockObjectiveCCustomAdapter() <ISMockCustomNetworkInitializeDelegate>

/**
 * You should hold a list of init delegates because the custom adapter init method might be
 * called more than once at the same time from different integrated adUnits/instances.
 * You must return the init result to all of the init calls.
*/
@property(nonatomic, strong) NSMutableSet<ISNetworkInitializationDelegate> *initializationDelegates;

// Optional variable sample
@property(nonatomic, assign) BOOL adapterDebug;

@end

/**
 * Most networks needs some configurations to use the sdk.
 * You should declare the keys needed for the sdk application level here
 * and access the data through the AdData class when needed.
*/
static NSString * const kAppIdField = @"app_level_key";

// Your adapter version
static NSString * const kAdapterVersion     = @"7.2.1.2";

@implementation ISMockObjectiveCCustomAdapter

# pragma mark - IronSource base adapter methods


- (instancetype)init
{
    self = [super init];
    if (self) {
        _initializationDelegates = [NSMutableSet<ISNetworkInitializationDelegate> new];
    }
    return self;
}
/**
 * The init method can be called multiple times.
 * You should manage the state of the sdk init process
 * and make sure all delegates gets the result callback.
 * @param adData the data for the current app
 * @param delegate the network initialization delegate to return result callbacks
*/

- (void)init:(ISAdData *)adData
    delegate:(id<ISNetworkInitializationDelegate>)delegate {
    
    // check if your sdk is already initialized
    if ([[ISMockCustomNetworkSdk sharedInstance] isInitialized]) {
        // if sdk is already initialized return success
        [delegate onInitDidSucceed];
        return;
    }
    
    // save init delegate to return the init result after completion
    [_initializationDelegates addObject:delegate];

    // if the init is in progress the init callback will return it to the smash
    if ([[ISMockCustomNetworkSdk sharedInstance] isInitInProgress]) {
        return;
    }
    
    // make sure the  app level configuration is retrieved
    NSString *sampleApplicationKey = adData.configuration[kAppIdField];
    if (sampleApplicationKey.length == 0) {
        [delegate onInitDidFailWithErrorCode:ISAdapterErrorMissingParams
                                errorMessage:[NSString stringWithFormat:@"missing value for key %@", kAppIdField]];
        return;
    }
    // optional adapter debug sample
    [[ISMockCustomNetworkSdk sharedInstance] setDebugMode:_adapterDebug];
    
    NSString *userId = adData.configuration[[ISDataKeys USER_ID]];
    if (userId) {
        [[ISMockCustomNetworkSdk sharedInstance] setUserId:userId];
        LogAdapterApi_Internal(@"set userId=%@", userId);
    }

    LogAdapterApi_Internal(@"init with %@ debugmode=%d", sampleApplicationKey, _adapterDebug);

    // call sdk init method
    [[ISMockCustomNetworkSdk sharedInstance] initWithApplicationKey:sampleApplicationKey initDelegate:self];
}

/**
 * The adapter version.
 * @return String representing the adapter version.
*/
- (NSString *)adapterVersion {
    // here you should return the adapter version
    return kAdapterVersion;
}

/**
 * The network sdk version - recommended not to put a hard coded value
 * @return String representing the network sdk version.
 */
- (NSString *)networkSDKVersion {
    // here you should return your sdk version
    return [[ISMockCustomNetworkSdk sharedInstance] sdkVersion];
}

# pragma mark - SampleNetworkInitializeDelegate callbacks

- (void)didInitialize {
    LogAdapterDelegate_Internal(@"");
    
    // iterate over your init delegates and return success
    for (id<ISNetworkInitializationDelegate> delegate in _initializationDelegates) {
        [delegate onInitDidSucceed];
    }
    // clear init delegates
    [_initializationDelegates removeAllObjects];
}

- (void)didInitializeFailWithErrorCode:(NSInteger)errorCode errorMessage:(NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"code = %ld, message = %@",(long)errorCode, errorMessage);

    // iterate over your init delegates and return failure
    for (id<ISNetworkInitializationDelegate> delegate in _initializationDelegates) {
        [delegate onInitDidFailWithErrorCode:errorCode errorMessage:errorMessage];
    }
    // clear init listeners
    [_initializationDelegates removeAllObjects];

}

#pragma mark - ISAdapterDebugInterface methods

/**
  * This is an optional api you can add by overriding the method.
  */
- (void)setAdapterDebug:(BOOL)adapterDebug {
    _adapterDebug = adapterDebug;
}

#pragma mark - Optional methods you can add and access from ad instance level if needed

/**
 * A sample of a method you could access from ad instance level.
 * @return the data needed
 */
-(NSString *) sampleAppLevelData {
    return @"sample app level data that you can access from ad instance level";
}


@end
