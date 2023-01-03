//
//  JivoSDKModule.m
//  MyTestApp
//
//  Created by Anton Karpushko on 01.07.2021.
//

#import <React/RCTLog.h>
#import <JivoSDK/JivoSDK-Swift.h>
//#import <JivoSDK/JivoSDK.h>

#import "JivoSDKModule.h"

@implementation JivoSDKModule

RCT_EXPORT_MODULE(JivoSDK);

_Nullable RCTResponseSenderBlock chattingUIDisplayRequestHandler;

+ (BOOL)requiresMainQueueSetup {
  return true;
}

- (id)init {
  if (self = [super init]) {
    [[JivoSDK chattingUI] setDelegate:self];
  }
  return self;
}

RCT_EXPORT_METHOD(startUpSession:
                  (NSString *)channelID
                  userToken:(NSString *)userToken
                  server:(NSString *)server) {
  dispatch_async(dispatch_get_main_queue(), ^{
    JivoSDKSessionServer serverValue = JivoSDKSessionServerAuto;
    if (server == NULL) {
      serverValue = JivoSDKSessionServerAuto;
    }
    else if ([server isEqual:@"auto"]) {
      serverValue = JivoSDKSessionServerAuto;
    }
    else if ([server isEqual:@"europe"]) {
      serverValue = JivoSDKSessionServerEurope;
    }
    else if ([server isEqual:@"russia"]) {
      serverValue = JivoSDKSessionServerRussia;
    }
    else if ([server isEqual:@"asia"]) {
      serverValue = JivoSDKSessionServerAsia;
    }
    else {
      serverValue = JivoSDKSessionServerAuto;
    }

    [[JivoSDK session] setPreferredServer:serverValue];
    [[JivoSDK session] startUpWithChannelID:channelID userToken:userToken];
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
    
    JivoSDKSessionClientInfo *clientInfo = [[JivoSDKSessionClientInfo alloc]
                                              initWithName:name
                                              email:email
                                              phone:phone
                                              brief:brief
                                            ];
    [[JivoSDK session] setClientInfo:clientInfo];
  });
}

RCT_EXPORT_METHOD(setSessionClientInfo:(NSDictionary *)clientInfoDictionary) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString * _Nullable nameValue = [clientInfoDictionary objectForKey:@"name"];
    NSString * _Nullable name;
    if ([nameValue isKindOfClass:[NSString class]] || nameValue == NULL) {
      name = nameValue;
    } else {
      RCTLogWarn(@"Invalid 'name' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable emailValue = [clientInfoDictionary objectForKey:@"email"];
    NSString * _Nullable email;
    if ([emailValue isKindOfClass:[NSString class]] || emailValue == NULL) {
      email = emailValue;
    } else {
      RCTLogWarn(@"Invalid 'email' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable phoneValue = [clientInfoDictionary objectForKey:@"phone"];
    NSString * _Nullable phone;
    if ([phoneValue isKindOfClass:[NSString class]] || phoneValue == NULL) {
      phone = phoneValue;
    } else {
      RCTLogWarn(@"Invalid 'phone' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable briefValue = [clientInfoDictionary objectForKey:@"brief"];
    NSString * _Nullable brief;
    if ([briefValue isKindOfClass:[NSString class]] || briefValue == NULL) {
      brief = briefValue;
    } else {
      RCTLogWarn(@"Invalid 'brief' field type: you should pass a value of the string type.");
    }
    
    JivoSDKSessionClientInfo *clientInfo = [[JivoSDKSessionClientInfo alloc]
                                              initWithName:name
                                              email:email
                                              phone:phone
                                              brief:brief
                                            ];
    [[JivoSDK session] setClientInfo:clientInfo];
  });
}

RCT_EXPORT_METHOD(setSessionCustomData:(NSArray *)customDataArray) {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableArray *fields = [NSMutableArray new];

    for (id item in customDataArray) {
      if (![item isKindOfClass:[NSDictionary class]]) {
        continue;
      }

      id titleValue = [item objectForKey:@"title"];
      if (![titleValue isKindOfClass:[NSString class]]) {
        titleValue = NULL;
      }

      id keyValue = [item objectForKey:@"key"];
      if (![keyValue isKindOfClass:[NSString class]]) {
        keyValue = NULL;
      }

      id contentValue = [item objectForKey:@"content"];
      if (![contentValue isKindOfClass:[NSString class]] || [contentValue length] == 0) {
        continue;
      }

      id linkValue = [item objectForKey:@"link"];
      if (![linkValue isKindOfClass:[NSString class]]) {
        linkValue = NULL;
      }

      JivoSDKSessionCustomDataField *field = [[JivoSDKSessionCustomDataField alloc] initWithTitle:titleValue key:keyValue content:contentValue link:linkValue];
      [fields addObject:field];
    }

    [[JivoSDK session] setCustomData:fields];
  });
}

RCT_EXPORT_METHOD(setPermissionAskingMomentAt:
                  (NSString *)moment
                  handler:(NSString *)handler) {
  dispatch_async(dispatch_get_main_queue(), ^{
    JivoSDKNotificationsPermissionAskingMoment momentValue;
    if ([moment isEqual:@"never"]) {
      momentValue = JivoSDKNotificationsPermissionAskingMomentNever;
    }
    else if ([moment isEqual:@"onconnect"]) {
      momentValue = JivoSDKNotificationsPermissionAskingMomentOnConnect;
    }
    else if ([moment isEqual:@"onappear"]) {
      momentValue = JivoSDKNotificationsPermissionAskingMomentOnAppear;
    }
    else if ([moment isEqual:@"onsend"]) {
      momentValue = JivoSDKNotificationsPermissionAskingMomentOnSend;
    }
    else {
      momentValue = JivoSDKNotificationsPermissionAskingMomentNever;
    }

    JivoSDKNotificationsPermissionAskingHandler handlerValue;
    if ([handler isEqual:@"sdk"]) {
      handlerValue = JivoSDKNotificationsPermissionAskingHandlerSdk;
    }
    else if ([moment isEqual:@"current"]) {
      handlerValue = JivoSDKNotificationsPermissionAskingHandlerCurrent;
    }
    else {
      handlerValue = JivoSDKNotificationsPermissionAskingHandlerCurrent;
    }

    [[JivoSDK notifications] setPermissionAskingAt:momentValue handler:handlerValue];
  });
}

RCT_EXPORT_METHOD(setPushToken:(NSString *)hex) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[JivoSDK notifications] setPushTokenHex:hex];
  });
}

RCT_EXPORT_METHOD(handlePushRawPayload:
                  (NSDictionary *)rawPayload
                  callback:(RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    bool isPushFromJivoBool = [[JivoSDK notifications] handleRemoteNotificationContainingUserInfo:rawPayload];
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

RCT_EXPORT_METHOD(isChattingUIPresented:(RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    bool isChattingUIDisplaying = [JivoSDK.chattingUI isDisplaying];
    NSNumber *isChattingUIDisplayingNSNumber = [[NSNumber alloc] initWithBool:isChattingUIDisplaying];
        
    NSArray *callbackData = @[isChattingUIDisplayingNSNumber];
    callback(callbackData);
  });
}

RCT_EXPORT_METHOD(setChattingUIDisplayRequestHandler:(RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    chattingUIDisplayRequestHandler = callback;
  });
}

RCT_EXPORT_METHOD(removeChattingUIDisplayRequestHandler) {
  dispatch_async(dispatch_get_main_queue(), ^{
    chattingUIDisplayRequestHandler = NULL;
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
    
    NSString * _Nullable inputPrefillValue = [uiConfigDictionary objectForKey:@"inputPrefill"];
    NSString * _Nullable inputPrefill;
    if ([inputPrefillValue isKindOfClass:[NSString class]] || inputPrefillValue == NULL) {
      inputPrefill = inputPrefillValue;
    } else {
      RCTLogWarn(@"Invalid 'inputPrefill' field type: you should pass a value of the string type.");
    }
    
    NSString * _Nullable activeMessageValue = [uiConfigDictionary objectForKey:@"activeMessage"];
    NSString * _Nullable activeMessage;
    if ([activeMessageValue isKindOfClass:[NSString class]] || activeMessageValue == NULL) {
      activeMessage = activeMessageValue;
    } else {
      RCTLogWarn(@"Invalid 'activeMessage' field type: you should pass a value of the string type.");
    }

    NSString * _Nullable offlineMessageValue = [uiConfigDictionary objectForKey:@"offlineMessage"];
    NSString * _Nullable offlineMessage;
    if ([offlineMessageValue isKindOfClass:[NSString class]] || offlineMessageValue == NULL) {
      offlineMessage = offlineMessageValue;
    } else {
      RCTLogWarn(@"Invalid 'offlineMessage' field type: you should pass a value of the string type.");
    }

    NSString *outcomingPaletteValue = [uiConfigDictionary objectForKey:@"outcomingPalette"];
    JivoSDKChattingPaletteAlias outcomingPalette = JivoSDKChattingPaletteAliasGreen;
    if ([outcomingPaletteValue isKindOfClass:[NSString class]]) {
      outcomingPalette = [self paletteAliasForString:outcomingPaletteValue];
    }
    else {
      RCTLogWarn(@"Invalid 'outcomingPalette' field type: you should pass a value of the string type.");
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
                                       inputPrefill:inputPrefill
                                       activeMessage:activeMessage
                                       offlineMessage:offlineMessage
                                       outcomingPalette:outcomingPalette
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

- (void)jivoDidRequestChattingUI {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (chattingUIDisplayRequestHandler != NULL) {
      chattingUIDisplayRequestHandler(@[]);
    }
  });
}

- (JivoSDKDebuggingLevel)debuggingLevelForString:(NSString *)string {
  if ([string isEqual:@"silent"]) {
    return JivoSDKDebuggingLevelSilent;
  } else if ([string isEqual:@"full"]) {
    return JivoSDKDebuggingLevelFull;
  }
  
  @throw([NSException exceptionWithName:@"Undefined debugging level name exception." reason:@"Could not parse the passed debugging level string." userInfo:nil]);
}

- (JivoSDKChattingPaletteAlias)paletteAliasForString:(NSString *)string {
  if ([string isEqual:@"green"]) {
    return JivoSDKChattingPaletteAliasGreen;
  }
  else if ([string isEqual:@"blue"]) {
    return JivoSDKChattingPaletteAliasBlue;
  }
  else if ([string isEqual:@"graphite"]) {
    return JivoSDKChattingPaletteAliasGraphite;
  }
  else {
    RCTLogWarn(@"Invalid 'outcomingPalette' field value. Please check the documentation for possible values. For now, fallback to 'green'.");
    return JivoSDKChattingPaletteAliasGreen;
  }
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
