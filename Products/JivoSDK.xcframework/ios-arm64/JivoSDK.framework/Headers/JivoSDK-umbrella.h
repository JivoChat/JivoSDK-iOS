#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JivoSDK-Bridging-Header.h"
#import "JivoSDK.h"

FOUNDATION_EXPORT double JivoSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char JivoSDKVersionString[];

