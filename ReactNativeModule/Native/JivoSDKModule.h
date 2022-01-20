//
//  JivoSDKModule.h
//  MyTestApp
//
//  Created by macbook on 01.07.2021.
//

#import <React/RCTBridgeModule.h>
#import <JivoSDK/JivoSDK-Swift.h>

@interface JivoSDKModule : NSObject <RCTBridgeModule, JivoSDKSessionDelegate, JivoSDKChattingUIDelegate>
+ (BOOL)requiresMainQueueSetup;
@end
