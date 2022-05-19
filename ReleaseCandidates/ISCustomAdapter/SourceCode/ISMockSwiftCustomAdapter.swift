//
//  ISSwiftCustomNetwork.swift
//  ISCustomAdapter
//
//  Created by Bar David on 02/11/2021.
//

@objc(ISMockSwiftCustomAdapter)
public class ISMockSwiftCustomAdapter : ISBaseNetworkAdapter, ISMockCustomNetworkInitializeDelegate {
    
    /**
     * You should declare the keys needed for the sdk instance level here
     * and access the data through the AdData class when needed.
     */
    static let sampleInstanceLevelKey = "instance_level_key"
    
    /**
     * Most networks needs some configurations to use the sdk.
     * You should declare the keys needed for the sdk application level here
     * and access the data through the AdData class when needed.
     */
    fileprivate let appIdField = "app_level_key"
    
    // Your adapter version
    fileprivate let customAdapterVersion = "7.2.1.2"
    
    /**
     * The init method can be called multiple times.
     * You should manage the state of the sdk init process
     * and make sure all delegates gets the result callback.
     * @param adData the data for the current app
     * @param delegate the network initialization delegate to return result callbacks
     */
    fileprivate var initializationDelegates = Array<ISNetworkInitializationDelegate>()
    
    // Optional variable sample
    fileprivate var adapterDebug = false
    
    public override func `init` (_ adData: ISAdData, delegate: ISNetworkInitializationDelegate) {
        // check if your sdk is already initialized
        if (ISMockCustomNetworkSdk.sharedInstance().isInitialized()) {
            // if sdk is already initialized return success
            delegate.onInitDidSucceed()
            return
        }
        
        // save init delegate to return the init result after completion
        initializationDelegates.append(delegate)
        
        // if the init is in progress the init callback will return it to the smash
        if (ISMockCustomNetworkSdk.sharedInstance().isInitInProgress()) {
            return
        }
        
        // make sure the  app level configuration is retrieved
        guard let sampleApplicationKey = adData.getString(self.appIdField) else {
            delegate.onInitDidFailWithErrorCode(ISAdapterErrors.missingParams.rawValue, errorMessage: "missing value for key \(self.appIdField)")
            return
        }
        
        // optional adapter debug sample
        ISMockCustomNetworkSdk.sharedInstance().setDebugMode(adapterDebug)
        
        if let userId = adData.getString(ISDataKeys.user_ID()) {
            ISMockCustomNetworkSdk.sharedInstance().setUserId(userId)
            NSLog("ADAPTER_API SwiftSampleCustomAdapter set userId=\(userId)");
        }
        
        NSLog("ADAPTER_API SwiftSampleCustomAdapter init with \(sampleApplicationKey) debugmode=\(adapterDebug)");
        
        // call sdk init method
        ISMockCustomNetworkSdk.sharedInstance().initWithApplicationKey(sampleApplicationKey, initDelegate: self)
    }
    
    // MARK:  CustomNetworkInitializeDelegate callbacks
    
    public func didInitialize() {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomNetwork didInitialize");
        
        // iterate over your init delegates and return success
        for delegate in initializationDelegates {
            delegate.onInitDidSucceed()
        }
        // clear init delegates
        initializationDelegates.removeAll()
    }
    
    public func didInitializeFailWithErrorCode(_ errorCode: Int, errorMessage: String!) {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomNetwork didInitializeFailWithErrorCode \(errorCode) and message \(String(describing: errorMessage))")
        
        // iterate over your init delegates and return failure
        for delegate in initializationDelegates {
            delegate.onInitDidFailWithErrorCode(errorCode, errorMessage: errorMessage)
            
        }
        // clear init delegates
        initializationDelegates.removeAll()
    }
    
    // MARK: ISAdapterDebugInterface methods
    
    public override func setAdapterDebug(_ adapterDebug: Bool) {
        self.adapterDebug = adapterDebug
    }
    
    // MARK: Optional methods you can add and access from ad instance level if needed
    
    /**
     * A sample of a method you could access from ad instance level.
     * @return the data needed
     */
    public func sampleAppLevelData() ->  String {
        return "sample app level data that you can access from ad instance level"
    }
    
    /**
     * The adapter version.
     * @return String representing the adapter version.
     */
    public override func adapterVersion() -> String {
        // here you should return the adapter version
        return self.customAdapterVersion;
    }
    
    /**
     * The network sdk version - recommended not to put a hard coded value
     * @return String representing the network sdk version.
     */
    public override func networkSDKVersion() -> String {
        // here you should return your sdk version
        return ISMockCustomNetworkSdk.sharedInstance().sdkVersion()
    }
}
