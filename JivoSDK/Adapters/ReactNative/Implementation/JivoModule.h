//
//  JivoModule.h
//

#import <React/RCTBridgeModule.h>
#import <JivoSDK/JivoSDK-Swift.h>

@interface JivoModule : NSObject <RCTBridgeModule, JVDisplayDelegate>
+ (BOOL)requiresMainQueueSetup;
@end
