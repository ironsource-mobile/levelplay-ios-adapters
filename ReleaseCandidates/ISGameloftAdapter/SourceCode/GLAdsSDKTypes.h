#pragma once

#if defined(_WIN32) || defined(_WIN64)
#ifdef Building_GLAdsSDK_DLL
#define GLAdsSDK_Export extern "C" __declspec(dllexport)
#else
#define GLAdsSDK_Export extern "C" __declspec(dllimport)
#endif
#define GLAdsSDK_STDCALL __stdcall
#else
#define GLAdsSDK_Export extern "C" __attribute__((visibility("default")))
#define GLAdsSDK_STDCALL
#endif

typedef enum
{
    GLAdsSDK_Result_Success,
    GLAdsSDK_Result_Error_Not_Initialized,
    GLAdsSDK_Result_Error_Already_Initialized,
    GLAdsSDK_Result_Error_Not_Enough_Memory,
    GLAdsSDK_Result_Error
} GLAdsSDK_Result;

typedef enum
{
    GLAdsSDK_AdType_Banner,
    GLAdsSDK_AdType_Interstitial,
    GLAdsSDK_AdType_Incentivized
} GLAdsSDK_AdType;

typedef enum
{
    GLAdsSDK_AdLoadFailedReason_Invalid_Server_Response,
    GLAdsSDK_AdLoadFailedReason_Network_Error,
    GLAdsSDK_AdLoadFailedReason_No_Ad_Available
} GLAdsSDK_AdLoadFailedReason;

typedef enum
{
    GLAdsSDK_AdShowFailedReason_Invalid_Server_Response,
    GLAdsSDK_AdShowFailedReason_Network_Error,
    GLAdsSDK_AdShowFailedReason_No_Ad_Available,
    GLAdsSDK_AdShowFailedReason_Already_Showing,
    GLAdsSDK_AdShowFailedReason_Cancelled,
    GLAdsSDK_AdShowFailedReason_WebView_Crash
} GLAdsSDK_AdShowFailedReason;

typedef enum
{
    GLAdsSDK_AdAlign_Top_Left,
    GLAdsSDK_AdAlign_Top_Center,
    GLAdsSDK_AdAlign_Top_Right,
    GLAdsSDK_AdAlign_Middle_Left,
    GLAdsSDK_AdAlign_Center,
    GLAdsSDK_AdAlign_Middle_Right,
    GLAdsSDK_AdAlign_Bottom_Left,
    GLAdsSDK_AdAlign_Bottom_Center,
    GLAdsSDK_AdAlign_Bottom_Right
} GLAdsSDK_AdAlign;

typedef struct
{
    void (GLAdsSDK_STDCALL *AdWasLoaded)(GLAdsSDK_AdType adType, const char* instance);
    void (GLAdsSDK_STDCALL *AdLoadFailed)(GLAdsSDK_AdType adType, const char* instance, GLAdsSDK_AdLoadFailedReason reason);
    void (GLAdsSDK_STDCALL *AdHasExpired)(GLAdsSDK_AdType adType, const char* instance);
    void (GLAdsSDK_STDCALL *AdWillShow)(GLAdsSDK_AdType adType, const char* instance);
    void (GLAdsSDK_STDCALL *AdShowFailed)(GLAdsSDK_AdType adType, const char* instance, GLAdsSDK_AdShowFailedReason reason);
    void (GLAdsSDK_STDCALL *AdClicked)(GLAdsSDK_AdType adType, const char* instance);
    void (GLAdsSDK_STDCALL *AdRewarded)(GLAdsSDK_AdType adType, const char* instance);
    void (GLAdsSDK_STDCALL *AdWasClosed)(GLAdsSDK_AdType adType, const char* instance);
} GLAdsSDK_Listener;
