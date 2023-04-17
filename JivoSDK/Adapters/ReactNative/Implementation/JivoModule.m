//
//  JivoModule.m
//

#import <React/RCTLog.h>
#import <JivoSDK/JivoSDK-Swift.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
//#import <JivoSDK/JivoSDK.h>

#import "JivoModule.h"

@implementation JivoModule

RCT_EXPORT_MODULE(Jivo);

_Nullable RCTResponseSenderBlock chattingUIDisplayRequestHandler;
NSDictionary *_config;

+ (BOOL)requiresMainQueueSetup {
  return true;
}

- (id)init {
  if (self = [super init]) {
    Jivo.display.delegate = self;
  }
  return self;
}

RCT_EXPORT_METHOD(setPreferredServer:(NSString *)server) {
  dispatch_async(dispatch_get_main_queue(), ^{
    JVSessionServer serverValue = JVSessionServerAuto;
    if (server == NULL) {
      serverValue = JVSessionServerAuto;
    }
    else if ([server isEqual:@"auto"]) {
      serverValue = JVSessionServerAuto;
    }
    else if ([server isEqual:@"europe"]) {
      serverValue = JVSessionServerEurope;
    }
    else if ([server isEqual:@"russia"]) {
      serverValue = JVSessionServerRussia;
    }
    else if ([server isEqual:@"asia"]) {
      serverValue = JVSessionServerAsia;
    }
    else {
      serverValue = JVSessionServerAuto;
    }

    [Jivo.session setPreferredServer:serverValue];
  });
}

RCT_EXPORT_METHOD(startUpSession:
                  (NSString *)channelID
                  userToken:(NSString *)userToken) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [Jivo.session startUpWithChannelID:channelID userToken:userToken];
  });
}

RCT_EXPORT_METHOD(setSessionContactInfo:(NSDictionary *)clientInfoDictionary) {
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
    
    JVSessionContactInfo *info;
    info = [[JVSessionContactInfo alloc]
            initWithName:name
            email:email
            phone:phone
            brief:brief];
    [Jivo.session setContactInfo:info];
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

      JVSessionCustomDataField *field;
      field = [[JVSessionCustomDataField alloc]
               initWithTitle:titleValue
               key:keyValue
               content:contentValue
               link:linkValue];
      [fields addObject:field];
    }

    [Jivo.session setCustomData:fields];
  });
}

RCT_EXPORT_METHOD(setPermissionAskingMomentAt:
                  (NSString *)moment) {
  dispatch_async(dispatch_get_main_queue(), ^{
    JVNotificationsPermissionAskingMoment momentValue;
    if ([moment isEqual:@"never"]) {
      momentValue = JVNotificationsPermissionAskingMomentNever;
    }
    else if ([moment isEqual:@"onconnect"]) {
      momentValue = JVNotificationsPermissionAskingMomentOnConnect;
    }
    else if ([moment isEqual:@"onappear"]) {
      momentValue = JVNotificationsPermissionAskingMomentOnAppear;
    }
    else if ([moment isEqual:@"onsend"]) {
      momentValue = JVNotificationsPermissionAskingMomentOnSend;
    }
    else {
      momentValue = JVNotificationsPermissionAskingMomentNever;
    }

    [Jivo.notifications setPermissionAskingAt:momentValue];
  });
}

RCT_EXPORT_METHOD(setPushToken:(NSString *)hex) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [Jivo.notifications setPushTokenHex:hex];
  });
}

RCT_EXPORT_METHOD(handlePushRawPayload:
                  (NSDictionary *)rawPayload) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [Jivo.notifications handleIncomingUserInfo:rawPayload completionHandler:nil];
  });
}

RCT_EXPORT_METHOD(shutDownSession) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [Jivo.session shutDown];
  });
}

RCT_EXPORT_METHOD(isChattingUIPresented:(RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    bool isChattingUIDisplaying = [Jivo.display isOnscreen];
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
    _config = [uiConfigDictionary copy];
    
    NSString * _Nullable localeIdentifier = [uiConfigDictionary objectForKey:@"localeIdentifier"];
    if ([localeIdentifier isKindOfClass:[NSString class]] || localeIdentifier == NULL) {
      NSLocale * _Nullable locale = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier];
      [Jivo.display setLocale:locale];
    } else {
      RCTLogWarn(@"Invalid 'localeIdentifier' field type: you should pass a value of the string type.");
    }
    
    NSString *outcomingPaletteValue = [uiConfigDictionary objectForKey:@"outcomingPalette"];
    if ([outcomingPaletteValue isKindOfClass:[NSString class]]) {
      [Jivo.display setPalette:[self paletteAliasForString:outcomingPaletteValue]];
    }
    else {
      RCTLogWarn(@"Invalid 'outcomingPalette' field type: you should pass a value of the string type.");
    }
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [Jivo.display presentOver:rootViewController];
  });
}

RCT_EXPORT_METHOD(presentChattingUI) {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [Jivo.display presentOver:rootViewController];
  });
}

RCT_EXPORT_METHOD(setDebuggingLevel:(NSString *)stringLevel) {
  dispatch_async(dispatch_get_main_queue(), ^{
    JVDebuggingLevel level;
    @try {
      level = [self debuggingLevelForString:stringLevel];
      Jivo.debugging.level = level;
    }
    @catch (NSException *exception) {
      RCTLogWarn(@"%@", exception.reason);
    }
  });
}

RCT_EXPORT_METHOD(archiveLogs:(RCTResponseSenderBlock)callback) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [Jivo.debugging archiveLogsWithCompletionHandler: ^void (NSURL * _Nullable url, JVDebuggingArchiveStatus status) {
      NSArray *callbackData = @[
        url.absoluteString,
        [self stringForArchivingStatus:status]
      ];
      
      callback(callbackData);
    }];
  });
}

- (void)jivoDisplayAsksToAppear:(Jivo * _Nonnull)sdk {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (chattingUIDisplayRequestHandler != NULL) {
      chattingUIDisplayRequestHandler(@[]);
    }
  });
}

- (void)jivoDisplayDidDisappear:(Jivo * _Nonnull)sdk {
}

- (void)jivoDisplayWillAppear:(Jivo * _Nonnull)sdk {
}

- (NSString *)jivoDisplayDefineText:(Jivo *)sdk forElement:(enum JVDisplayElement)element {
  switch (element) {
    case JVDisplayElementHeaderTitle: {
      NSString * _Nullable titlePlaceholderValue = [_config objectForKey:@"titlePlaceholder"];
      if ([titlePlaceholderValue isKindOfClass:[NSString class]] || titlePlaceholderValue == NULL) {
        return titlePlaceholderValue;
      } else {
        RCTLogWarn(@"Invalid 'titlePlaceholder' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    case JVDisplayElementHeaderSubtitle: {
      NSString * _Nullable subtitleCaptionValue = [_config objectForKey:@"subtitleCaption"];
      if ([subtitleCaptionValue isKindOfClass:[NSString class]] || subtitleCaptionValue == NULL) {
        return subtitleCaptionValue;
      } else {
        RCTLogWarn(@"Invalid 'subtitleCaption' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    case JVDisplayElementReplyPlaceholder: {
      NSString * _Nullable inputPlaceholderValue = [_config objectForKey:@"inputPlaceholder"];
      if ([inputPlaceholderValue isKindOfClass:[NSString class]] || inputPlaceholderValue == NULL) {
        return inputPlaceholderValue;
      } else {
        RCTLogWarn(@"Invalid 'inputPlaceholder' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    case JVDisplayElementReplyPrefill: {
      NSString * _Nullable inputPrefillValue = [_config objectForKey:@"inputPrefill"];
      if ([inputPrefillValue isKindOfClass:[NSString class]] || inputPrefillValue == NULL) {
        return inputPrefillValue;
      } else {
        RCTLogWarn(@"Invalid 'inputPrefill' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    case JVDisplayElementMessageOffline: {
      NSString * _Nullable offlineMessageValue = [_config objectForKey:@"offlineMessage"];
      if ([offlineMessageValue isKindOfClass:[NSString class]] || offlineMessageValue == NULL) {
        return offlineMessageValue;
      } else {
        RCTLogWarn(@"Invalid 'offlineMessage' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    case JVDisplayElementMessageHello: {
      NSString * _Nullable activeMessageValue = [_config objectForKey:@"activeMessage"];
      if ([activeMessageValue isKindOfClass:[NSString class]] || activeMessageValue == NULL) {
        return activeMessageValue;
      } else {
        RCTLogWarn(@"Invalid 'activeMessage' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    default: {
      return nil;
    }
  }
}

- (UIColor *)jivoDisplayDefineColor:(Jivo *)sdk forElement:(enum JVDisplayElement)element {
  switch (element) {
    case JVDisplayElementHeaderTitle: {
      NSString * _Nullable titleColorHexString = [_config objectForKey:@"titleColor"];
      if ([titleColorHexString isKindOfClass:[NSString class]] || titleColorHexString == NULL) {
        return [self colorFromHexString:titleColorHexString];
      } else {
        RCTLogWarn(@"Invalid 'titleColor' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    case JVDisplayElementHeaderSubtitle: {
      NSString * _Nullable subtitleColorHexString = [_config objectForKey:@"subtitleColor"];
      if ([subtitleColorHexString isKindOfClass:[NSString class]] || subtitleColorHexString == NULL) {
        return [self colorFromHexString:subtitleColorHexString];
      } else {
        RCTLogWarn(@"Invalid 'subtitleColor' field type: you should pass a value of the string type.");
        return nil;
      }
    }
      
    default: {
      return nil;
    }
  }
}

- (UIImage *)jivoDisplayDefineImage:(Jivo *)sdk forElement:(enum JVDisplayElement)element {
  return nil;
}

//- (void)jivoCustomize:(JivoSDK *)sdk defineImageForElement:(enum JivoSDKChattingUIElement)forElement resolveBlock:(void (^)(UIImage *))resolveBlock {
//  resolveBlock(nil);
//
//  NSObject * _Nullable iconValue = [uiConfigDictionary objectForKey:@"icon"];
//  BOOL useDefaultIcon;
//  UIImage * _Nullable icon;
//  if ([iconValue isKindOfClass:[NSDictionary class]]) {
//    useDefaultIcon = NO;
//    NSString *uriValue = [(NSDictionary * _Nullable)iconValue objectForKey:@"uri"];
//    if ([uriValue isKindOfClass:[NSString class]]) {
//      NSURL * _Nullable iconURL = [[NSURL alloc] initWithString:uriValue];
//      NSData *iconData = [[NSData alloc] initWithContentsOfURL:iconURL];
//      icon = [[UIImage alloc] initWithData:iconData];
//    } else {
//      if (iconValue != NULL) {
//        RCTLogWarn(@"Invalid 'icon.uri' field type: you should pass a value of the string type.");
//      }
//    }
//  } else if ([iconValue isKindOfClass:[NSString class]]) {
//    NSString * _Nullable iconStringValue = (NSString * _Nullable)iconValue;
//    if ([iconStringValue isEqual:@"default"]) {
//      useDefaultIcon = YES;
//    } else if ([iconStringValue isEqual:@"hidden"]) {
//      useDefaultIcon = NO;
//    } else {
//      useDefaultIcon = YES;
//      RCTLogWarn(@"Invalid 'icon' field string value: you should pass a value that takes one of the following values: 'default', 'hidden'");
//    }
//  } else if (iconValue == NULL) {
//    useDefaultIcon = YES;
//  } else {
//    useDefaultIcon = YES;
//    RCTLogWarn(@"Invalid 'icon' field type: you should pass a value of the Object type (image asset) or string type that takes one of the following values: 'default', 'hidden'");
//  }
//}

- (JVDebuggingLevel)debuggingLevelForString:(NSString *)string {
  if ([string isEqual:@"silent"]) {
    return JVDebuggingLevelSilent;
  } else if ([string isEqual:@"full"]) {
    return JVDebuggingLevelFull;
  }
  
  @throw([NSException exceptionWithName:@"Undefined debugging level name exception." reason:@"Could not parse the passed debugging level string." userInfo:nil]);
}

- (JVDisplayPaletteAlias)paletteAliasForString:(NSString *)string {
  if ([string isEqual:@"green"]) {
    return JVDisplayPaletteAliasGreen;
  }
  else if ([string isEqual:@"blue"]) {
    return JVDisplayPaletteAliasBlue;
  }
  else if ([string isEqual:@"graphite"]) {
    return JVDisplayPaletteAliasGraphite;
  }
  else {
    RCTLogWarn(@"Invalid 'outcomingPalette' field value. Please check the documentation for possible values. For now, fallback to 'green'.");
    return JVDisplayPaletteAliasGreen;
  }
}

- (NSString *)stringForArchivingStatus:(JVDebuggingArchiveStatus)status {
  switch (status) {
  case JVDebuggingArchiveStatusSuccess:
    return @"success";
    
  case JVDebuggingArchiveStatusFailedAccessing:
    return @"failedAccessing";
    
  case JVDebuggingArchiveStatusFailedPreparing:
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
