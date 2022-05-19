//
//  ISSwiftCustomInterstitial.swift
//  ISCustomAdapter
//
//  Created by Bar David on 07/11/2021.
//


@objc(ISMockSwiftCustomInterstitial)
public class ISMockSwiftCustomInterstitial : ISBaseInterstitial, ISMockCustomNetworkInterstitialAdDelegate {
    
    /**
     * Here you should declare the variables needed to
     * operate ad instance and return all callbacks successfully.
     * In this example we only need the delegate.
     */
    fileprivate var adDelegate: ISInterstitialAdDelegate? = nil
    fileprivate var instanceData : String? = nil
    
    // MARK: IronSource ad lifecycle methods
    
    /**
     * This method will be called once the mediation tries to load your instance.
     * Here you should attempt to load you ad instance and make
     * sure to return the load result callbacks to the ad delegate.
     * @param adData the data for the current ad
     * @param delegate the ad delegate to return lifecycle callbacks
     */
    
    public override func loadAd(with adData: ISAdData, delegate: ISInterstitialAdDelegate) {

        // save delegate
        self.adDelegate = delegate

        // validate the data needed and if data is not valid return load failed
        self.instanceData = adData.getString(ISMockSwiftCustomAdapter.sampleInstanceLevelKey)

        guard let instanceData = self.instanceData else {
            // return load failed with error code for missing params and a message stating which parameter is invalid
            delegate.adDidFailToLoadWith(ISAdapterErrorType.internal, errorCode: ISAdapterErrors.missingParams.rawValue, errorMessage: "missing value for key \(ISMockSwiftCustomAdapter.sampleInstanceLevelKey)")
            return

        }

        // example of data retrieved from your network adapter
        // optional when this data is required
        guard let networkAdapter = getNetworkAdapter() as? ISMockSwiftCustomAdapter else {
            delegate.adDidFailToLoadWith(ISAdapterErrorType.internal, errorCode: ISAdapterErrors.missingParams.rawValue, errorMessage: "missing network adapter")
            return
        }

        // call network level method
        ISMockCustomNetworkSdk.sharedInstance().setExtraData(networkAdapter.sampleAppLevelData())

        // load interstitial ad
        NSLog("ADAPTER_API ISSwiftCustomInterstitial load ad with \(instanceData)");

        ISMockCustomNetworkSdk.sharedInstance().loadInterstitialAd(withInstanceData: instanceData, adDelegate: self)
    }
    
    
    /**
     * This method will be called once the mediation tries to show your instance.
     * Here you should attempt to show your ad instance
     * and return the lifecycle callbacks to the ad delegate.
     * @param adData the data for the current ad
     * @param delegate the ad delegate to return lifecycle callbacks
     */
    public override func showAd(with viewController: UIViewController, adData: ISAdData, delegate: ISInterstitialAdDelegate) {
        
        //save the delegate
        self.adDelegate = delegate
        guard let instanceData = adData.getString(ISMockSwiftCustomAdapter.sampleInstanceLevelKey) else {
            return
        }
        
        // verify you have an ad to show for this configuration
        guard (ISMockCustomNetworkSdk.sharedInstance().isAdReady(withInstanceData: instanceData)) else {
            // return show failed callback
            delegate.adDidFailToShowWithErrorCode(ISAdapterErrors.internal.rawValue, errorMessage: "ad is not ready to show for the current instanceData")
            return
        }
        
        NSLog("ADAPTER_API ISSwiftCustomInterstitial show ad with \(instanceData)");
        
        // show interstitial ad
        ISMockCustomNetworkSdk.sharedInstance().showInterstitialAd(withInstanceData: instanceData, adDelegate: self)
    }
    
    /**
     * This method should indicate if you have an ad ready to show for the this adData configurations
     * @param adData the data for the current ad
     * @return true if you have an ad ready and false if not
     */
    
    public override func isAdAvailable(with adData: ISAdData) -> Bool {
        if let instanceData = adData.getString(ISMockSwiftCustomAdapter.sampleInstanceLevelKey) {
            return ISMockCustomNetworkSdk.sharedInstance().isAdReady(withInstanceData: instanceData)
        }
        else {
            return false
        }
    }
    
    // MARK: CustomNetworkInterstitialAdDelegate callbacks
    
    public func adLoaded() {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomInterstitial didLoadAd \(String(describing: instanceData))");
        
        adDelegate?.adDidLoad()
    }
    
    public func adLoadFailedWithErrorCode(_ errorCode: Int, errorMessage: String!) {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomInterstitial didLoadAdFailWithErrorCode \(String(describing: instanceData)) with error code \(errorCode) and message \(String(describing: errorMessage))");
        adDelegate?.adDidFailToLoadWith(ISAdapterErrorType.internal, errorCode: errorCode, errorMessage: errorMessage)
    }
    
    public func adShowSucceed() {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomInterstitial didShowAd \(String(describing: instanceData))");
        
        adDelegate?.adDidShowSucceed()
    }
    
    public func adShowFailedWithErrorCode(_ errorCode: Int, errorMessage: String!) {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomInterstitial didShowAdFailWithErrorCode \(String(describing: instanceData)) with error code \(errorCode) and message \(String(describing: errorMessage))");
        
        adDelegate?.adDidFailToShowWithErrorCode(errorCode, errorMessage: errorMessage)
    }
    
    public func adOpened() {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomInterstitial didAdOpen \(String(describing: instanceData))");
        adDelegate?.adDidOpen()
    }
    
    public func adClosed() {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomInterstitial didAdClose \(String(describing: instanceData))");
        adDelegate?.adDidClose()
    }
    
    public func adClicked() {
        NSLog("ADAPTER_DELEGATE ISSwiftCustomInterstitial didAdClick \(String(describing: instanceData))");
        adDelegate?.adDidClick()
    }
    
}
