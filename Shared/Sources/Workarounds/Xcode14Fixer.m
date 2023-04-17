//
//  Xcode14Fixer.m
//  App
//
//  Created by Stan Potemkin on 14.09.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#if ENV_DEBUG
@interface Xcode14Beta4Fixer : NSObject
@end

@implementation Xcode14Beta4Fixer
+ (void)load
{
    Class cls = NSClassFromString(@"_UINavigationBarContentViewLayout");
    SEL selector = @selector(valueForUndefinedKey:);
    Method impMethod = class_getInstanceMethod([self class], selector);

    if (impMethod) {
        class_addMethod(cls, selector, method_getImplementation(impMethod), method_getTypeEncoding(impMethod));
    }
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}
@end
#endif
