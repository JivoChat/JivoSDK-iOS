//
//  JivoSDKModule.m
//  MyTestApp
//
//  Created by Anton Karpushko on 01.07.2021.
//

#import <React/RCTLog.h>
#import <JivoSDK/JivoSDK.h>

#import "JivoSDKModule.h"

@implementation JivoSDKModule

RCT_EXPORT_MODULE(JivoSDK);

RCT_EXPORT_METHOD(startUpSession:
                  (NSString *)channelID
                  userToken:(NSString *)userToken) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[JivoSDK session] startUpWithChannelID:channelID userToken:userToken];
  });
}

RCT_EXPORT_METHOD(setSessionCallbacks) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[JivoSDK session] setDelegate:self];
  });
}

RCT_EXPORT_METHOD(updateSessionCustomData:(NSDictionary *)customDataDictionary) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString * _Nullable nameValue = [customDataDictionary objectForKey:@"name"];
    NSString * _Nullable name;
    if ([nameValue isKindOfClass:[NSString class]] || nameValue == NULL) {
      name = nameValue;
    } else {
      RCTLogWarn(@"Invalid 'name' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable emailValue = [customDataDictionary objectForKey:@"email"];
    NSString * _Nullable email;
    if ([emailValue isKindOfClass:[NSString class]] || emailValue == NULL) {
      email = emailValue;
    } else {
      RCTLogWarn(@"Invalid 'email' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable phoneValue = [customDataDictionary objectForKey:@"phone"];
    NSString * _Nullable phone;
    if ([phoneValue isKindOfClass:[NSString class]] || phoneValue == NULL) {
      phone = phoneValue;
    } else {
      RCTLogWarn(@"Invalid 'phone' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable briefValue = [customDataDictionary objectForKey:@"brief"];
    NSString * _Nullable brief;
    if ([briefValue isKindOfClass:[NSString class]] || briefValue == NULL) {
      brief = briefValue;
    } else {
      RCTLogWarn(@"Invalid 'brief' field type: you should pass a value of the string type.");
    }
    
    JivoSDKSessionCustomData *customData = [[JivoSDKSessionCustomData alloc]
                                              initWithName:name
                                              email:email
                                              phone:phone
                                              brief:brief
                                            ];
    [[JivoSDK session] updateCustomData:customData];
  });
}

RCT_EXPORT_METHOD(setPushToken:(NSString *)hex) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[JivoSDK session] setPushTokenHex:hex];
  });
}

RCT_EXPORT_METHOD(handlePushRawPayload:
                  (NSDictionary *)rawPayload
                  deliveryDate:(double)deliveryDateDouble
                  callback:(RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDate *deliveryDate = [[NSDate alloc] initWithTimeIntervalSince1970:deliveryDateDouble];
    bool isPushFromJivoBool = [[JivoSDK session] detectPushPayload:rawPayload];
    NSNumber *isPushFromJivoNSNumber = [[NSNumber alloc] initWithBool:isPushFromJivoBool];
    
    NSArray *callbackData = @[isPushFromJivoNSNumber];
    callback(callbackData);
  });
}

RCT_EXPORT_METHOD(shutDownSession) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[JivoSDK session] shutDown];
  });
}

RCT_EXPORT_METHOD(presentChattingUIWithConfig:(nullable NSDictionary *)uiConfigDictionary) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString * _Nullable localeIdentifier = [uiConfigDictionary objectForKey:@"localeIdentifier"];
    NSLocale * _Nullable locale;
    if ([localeIdentifier isKindOfClass:[NSString class]] || localeIdentifier == NULL) {
      locale = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier];
    } else {
      RCTLogWarn(@"Invalid 'localeIdentifier' field type: you should pass a value of the string type.");
    }
    
    NSObject * _Nullable iconValue = [uiConfigDictionary objectForKey:@"icon"];
    BOOL useDefaultIcon;
    UIImage * _Nullable icon;
    if ([iconValue isKindOfClass:[NSDictionary class]]) {
      useDefaultIcon = NO;
      NSString *uriValue = [(NSDictionary * _Nullable)iconValue objectForKey:@"uri"];
      if ([uriValue isKindOfClass:[NSString class]]) {
        NSURL * _Nullable iconURL = [[NSURL alloc] initWithString:uriValue];
        NSData *iconData = [[NSData alloc] initWithContentsOfURL:iconURL];
        icon = [[UIImage alloc] initWithData:iconData];
      } else {
        if (iconValue != NULL) {
          RCTLogWarn(@"Invalid 'icon.uri' field type: you should pass a value of the string type.");
        }
      }
    } else if ([iconValue isKindOfClass:[NSString class]]) {
      NSString * _Nullable iconStringValue = (NSString * _Nullable)iconValue;
      if ([iconStringValue isEqual:@"default"]) {
        useDefaultIcon = YES;
      } else if ([iconStringValue isEqual:@"hidden"]) {
        useDefaultIcon = NO;
      } else {
        useDefaultIcon = YES;
        RCTLogWarn(@"Invalid 'icon' field string value: you should pass a value that takes one of the following values: 'default', 'hidden'");
      }
    } else if (iconValue == NULL) {
      useDefaultIcon = YES;
    } else {
      useDefaultIcon = YES;
      RCTLogWarn(@"Invalid 'icon' field type: you should pass a value of the Object type (image asset) or string type that takes one of the following values: 'default', 'hidden'");
    }
    
    NSString * _Nullable titlePlaceholderValue = [uiConfigDictionary objectForKey:@"titlePlaceholder"];
    NSString * _Nullable titlePlaceholder;
    if ([titlePlaceholderValue isKindOfClass:[NSString class]] || titlePlaceholderValue == NULL) {
      titlePlaceholder = titlePlaceholderValue;
    } else {
      RCTLogWarn(@"Invalid 'titlePlaceholder' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable titleColorHexString = [uiConfigDictionary objectForKey:@"titleColor"];
    UIColor * _Nullable titleColor;
    if ([titleColorHexString isKindOfClass:[NSString class]] || titleColorHexString == NULL) {
      titleColor = [self colorFromHexString:titleColorHexString];
    } else {
      RCTLogWarn(@"Invalid 'titleColor' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable subtitleColorHexString = [uiConfigDictionary objectForKey:@"subtitleColor"];
    UIColor * _Nullable subtitleColor;
    if ([subtitleColorHexString isKindOfClass:[NSString class]] || subtitleColorHexString == NULL) {
      subtitleColor = [self colorFromHexString:subtitleColorHexString];
    } else {
      RCTLogWarn(@"Invalid 'subtitleColor' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable subtitleCaptionValue = [uiConfigDictionary objectForKey:@"subtitleCaption"];
    NSString * _Nullable subtitleCaption;
    if ([subtitleCaptionValue isKindOfClass:[NSString class]] || subtitleCaptionValue == NULL) {
      subtitleCaption = subtitleCaptionValue;
    } else {
      RCTLogWarn(@"Invalid 'subtitleCaption' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable inputPlaceholderValue = [uiConfigDictionary objectForKey:@"inputPlaceholder"];
    NSString * _Nullable inputPlaceholder;
    if ([inputPlaceholderValue isKindOfClass:[NSString class]] || inputPlaceholderValue == NULL) {
      inputPlaceholder = inputPlaceholderValue;
    } else {
      RCTLogWarn(@"Invalid 'inputPlaceholder' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable activeMessageValue = [uiConfigDictionary objectForKey:@"activeMessage"];
    NSString * _Nullable activeMessage;
    if ([activeMessageValue isKindOfClass:[NSString class]] || activeMessageValue == NULL) {
      activeMessage = activeMessageValue;
    } else {
      RCTLogWarn(@"Invalid 'activeMessage' field type: you should pass a value of the string type.");
    }
    
    JivoSDKChattingConfig *uiConfig = [[JivoSDKChattingConfig alloc]
                                       initWithLocale:locale
                                       useDefaultIcon:useDefaultIcon
                                       customIcon:icon
                                       titlePlaceholder:titlePlaceholder
                                       titleColor:titleColor
                                       subtitleCaption:subtitleCaption
                                       subtitleColor:subtitleColor
                                       inputPlaceholder:inputPlaceholder
                                       activeMessage:activeMessage
                                      ];

    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [JivoSDK.chattingUI presentOver:rootViewController withConfig:uiConfig];
  });
}

RCT_EXPORT_METHOD(presentChattingUI) {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [JivoSDK.chattingUI presentOver:rootViewController];
  });
}

RCT_EXPORT_METHOD(setDebuggingLevel:(NSString *)stringLevel) {
  dispatch_async(dispatch_get_main_queue(), ^{
    JivoSDKDebuggingLevel level;
    @try {
      level = [self debuggingLevelForString:stringLevel];
      JivoSDK.debugging.level = level;
    }
    @catch (NSException *exception) {
      RCTLogWarn(@"%@", exception.reason);
    }
  });
}

RCT_EXPORT_METHOD(archiveLogs:(RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [JivoSDK.debugging archiveLogsWithCompletion: ^void (NSURL * _Nullable url, JivoSDKArchivingStatus status) {
      NSArray *callbackData = @[
        url.absoluteString,
        [self stringForArchivingStatus:status]
      ];
      
      callback(callbackData);
    }];
  });
}

RCTResponseSenderBlock sessionDelegateRCTCallback;

+ (BOOL)requiresMainQueueSetup {
  return true;
}

- (JivoSDKDebuggingLevel)debuggingLevelForString:(NSString *)string {
  if ([string isEqual:@"silent"]) {
    return JivoSDKDebuggingLevelSilent;
  } else if ([string isEqual:@"full"]) {
    return JivoSDKDebuggingLevelFull;
  }
  
  @throw([NSException exceptionWithName:@"Undefined debugging level name exception." reason:@"Could not parse the passed debugging level string." userInfo:nil]);
}

- (NSString *)stringForArchivingStatus:(JivoSDKArchivingStatus)status {
  switch (status) {
  case JivoSDKArchivingStatusSuccess:
    return @"success";
    
  case JivoSDKArchivingStatusFailedAccessing:
    return @"failedAccessing";
    
  case JivoSDKArchivingStatusFailedPreparing:
    return @"failedPreparing";
  }
}

- (nullable UIColor *)colorFromHexString:(NSString *)hexString {
  unsigned rgbValue = 0;
  if ([hexString isEqual: @""] || hexString == NULL) {
    return NULL;
  }
  
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  
  @try {
    [scanner scanString:@"#" intoString:NULL]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
  }
  @catch (NSException *exception) {
    RCTLogWarn(@"Could not parse passed color hex string due to exception of type NSException: %@", exception.reason);
    
    return nil;
  }
}

@end
