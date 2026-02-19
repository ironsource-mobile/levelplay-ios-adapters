# Changelog

## Version 5.2.0
* Supporting SDK version 6.21.1

## Version 5.1.0
* Supporting Meta Audience Network SDK version 6.21.0
* Requirements:
  * This SDK version is compatible with iOS 13 or higher
  * This SDK requires you to use Xcode 26 or higher when building your application
* For more details see [Meta Audience Network Changelog](https://developers.facebook.com/docs/audience-network/setting-up/platform-setup/ios/changelog#6_21_0)

## Version 5.0.0
* The adapter is compatible with LevelPlay 9.0.0 and above

---

### ⚠️ Breaking Change – Minimum SDK Requirement

**All adapter releases listed **above** this section support LevelPlay SDK 9.0.0 and above only.**  
Adapter releases listed **below this section** continue to support earlier LevelPlay SDK versions.

---

## Version 4.3.52
* Improved handling of Interstitial show failures

## Version 4.3.51
* Supporting Meta Audience Network SDK version 6.20.1
* **Important!** This adapter is compatible with ironSource SDK 8.9.0 and above

## Version 4.3.50
* Supporting Meta Audience Network SDK version 6.20.0

## Version 4.3.49
* Supporting Meta Audience Network SDK version 6.17.1

## Version 4.3.48
* Supporting Meta Audience Network SDK version 6.17.0

## Version 4.3.47
* Supporting Meta Audience Network SDK version 6.16.0
* Requires Xcode 16
* **Important!** This adapter is compatible with ironSource SDK 8.5.0 and above

## Version 4.3.46
* Supporting Meta Audience Network SDK version 6.15.2
* Supporting Native ads
* **Important!** This adapter is compatible with ironSource SDK 8.4.0 and above

## Version 4.3.45
* Supporting Meta Audience Network SDK version 6.15.1

## Version 4.3.44
* Supporting Meta Audience Network SDK version 6.15.0

## Version 4.3.43
* Fix bug related to building the adapter with arm 64 simulators

## Version 4.3.42
* Resolve potential crash, experienced when using adapter 4.3.41

## Version 4.3.41
* Compatible with ironSource SDK 7.5.0
* **Important!** This adapter is deprecated, use 4.3.42 instead

## Version 4.3.40
* Supporting Meta Audience Network SDK version 6.14.0

## Version 4.3.39
* **Important!** This adapter is compatible with ironSource SDK 7.3.0 and above

## Version 4.3.38
* Supporting Meta Audience Network SDK version 6.12.0

## Version 4.3.37
* Supporting Meta Audience Network SDK version 6.11.2
* Supporting adapter as open-source

## Version 4.3.36
* Supporting Meta Audience Network SDK version 6.11.1
* Support iOS 15.5

## Version 4.3.35
* Supporting Meta Audience Network SDK version 6.11.0

## Version 4.3.34
* Supporting Meta Audience Network SDK version 6.10.0
* New SetMetaData flag was added Meta_Mixed_Audience, to support Meta Mixed Audience reporting

## Version 4.3.33
* Supporting FAN SDK version 6.9.0
* CoreKit dependency was removed
* [Xcode 13](https://developer.apple.com/xcode/) is required to build apps that integrate this version of Audience Network SDK
* Swift dependency is required to integrate this version of Audience Network SDK

## Version 4.3.32
* Potential crash fix

## Version 4.3.31
* Potential crash fix

## Version 4.3.30
* Supporting FAN SDK version 6.8.0

## Version 4.3.29
* **Important!** This adapter is compatible with ironSource SDK 7.1.10 and above

## Version 4.3.28
* Supporting FAN SDK version 6.6.0
* FAN SDK released as XCFramework

## Version 4.3.27
* Supporting FAN SDK version 6.5.1

## Version 4.3.26
* Supporting FAN SDK version 6.5.0

## Version 4.3.25
* Supporting FAN SDK version 6.4.1

## Version 4.3.24
* Supporting FAN SDK version 6.3.1

## Version 4.3.23
* Supporting FAN SDK version 6.3.0

## Version 4.3.22
* Supporting FAN SDK version 6.2.1
* iOS 14 Support

## Version 4.3.21
* Supporting FAN SDK version 6.2.0

## Version 4.3.20
* Supporting FAN SDK version 6.0.0
* **Important!** This adapter is compatible with ironSource SDK 7.0.2 and above

## Version 4.3.19
* Support FAN In App Bidding for banners

## Version 4.3.18
* Supporting FAN SDK version 5.10.1

## Version 4.3.17
* Supporting FAN SDK version 5.10.0
* CCPA support, by setting FAN Limited Data Use flag before initializing ironSource Mediation. Read more about FAN implementation [here](https://developers.facebook.com/docs/marketing-apis/data-processing-options#audience-network-sdk)

## Version 4.3.16
* Caching improvements
* **Important!** This adapter is compatible with ironSource SDK 6.17.0 and above

## Version 4.3.15
* Supporting FAN SDK version 5.9.0

## Version 4.3.14
* Init process improvements

## Version 4.3.13
* Supporting FAN SDK version 5.8.0

## Version 4.3.12
* Bug fix – Banner sizes are currently sent correctly, for all banner types

## Version 4.3.11
* Supporting SDK version 5.7.1
* Note: FAN SDK will no longer successfully link with projects which have bitcode enabled, that are built with Xcode10

## Version 4.3.10
* Supporting SDK version 5.6.1

## Version 4.3.9
* Support Meta In App Bidding, Rewarded Video and Interstitial

## Version 4.3.8
* Supporting SDK version 5.6.0

## Version 4.3.7
* Supporting SDK version 5.5.1
* iOS 13 ready

## Version 4.3.6
* Please note – Due to the collision between Meta SDK and the FBSDKCoreKit frameworks – Starting this adapter (4.3.6), Meta adapter will not hold the network's SDK within the adapter and needs to be added separately as a framework file. If you are updating Meta adapter to this or higher version, please make sure you also include Meta Audience Network SDK. The SDKs are mentioned in the [integration guide](https://developers.is.com/ironsource-mobile/ios/facebook-mediation-guide/).

## Version 4.3.5
* Supporting SDK version 5.5.0
* Added dependency to FBBSDKCoreKit_Basics
* Removed dependency to CoreLocation.framework

## Version 4.3.4
* Supporting SDK version 5.3.2

## Version 4.3.3
* Supporting SDK version 5.1.1
* Synchronization minor bug fixed
* Supporting FAN's isInAdsProcess

## Version 4.3.2
* As of version 5.0.0, FAN bumped the minimum support iOS version to 9.0. This adapter contains logic to keep the adapter from initiating FAN with versions lower than that, in order to prevent possible crashes

## Version 4.3.1
* Supporting SDK version 5.1.0

## Version 4.3.0
* Adjustments to support latest banner enhancements

## Version 4.1.4
* Adjustments to support latest banner enhancements

## Version 4.1.3
* Supporting SDK version 4.28.0

## Version 4.1.2
* Adjust Banner mediation core logic – banner refresh rate is now enforced by the mediation layer (Developers should turn off refresh rate at the networks dashboard)
