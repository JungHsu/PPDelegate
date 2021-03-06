//
//  PPDelegate.m
//  转发器
//
//  Created by xuzhongping on 2016/12/7.
//  Copyright © 2016年 xuzhongping. All rights reserved.
//

#import "PPDelegate.h"
#import <objc/message.h>

typedef id(^WeakArrayObj)(void);

@interface PPDelegate ()

@property (nonatomic,strong)NSMutableArray *delegates;

@end

@implementation PPDelegate

+ (instancetype)delegate{
    return [PPDelegate alloc];
}

- (void)addDelegates:(NSArray *)delegates forTarget:(id)target{
    [self addDelegates:delegates forTarget:target customDelegateProperty:nil];
}

- (void)addDelegates:(NSArray *)delegates forTarget:(id)target customDelegateProperty:(NSString *)property{
    [self.delegates removeAllObjects];
    [self reference:delegates];

    if (!property) {
        if ([self checkoutHasIvar:target]) return;
        if ([self checkoutHasProperty:target]) return;
    }else {
        [target setValue:self forKey:property];
    }

}



- (BOOL)checkoutHasIvar:(id)target{
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList([target class], &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([ivarName hasSuffix:@"delegate"]) {
            [target setValue:self forKey:ivarName];
            return YES;
        }
    }
    return NO;
}

- (BOOL)checkoutHasProperty:(id)target{
     unsigned int count = 0;
        objc_property_t *propertyList = class_copyPropertyList([target class], &count);
    
        for (int i = 0; i < count; i++) {
            objc_property_t property = propertyList[i];
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
            if ([propertyName hasSuffix:@"delegate"]) {
                [target setValue:self forKey:propertyName];
                return YES;
            }
        }
    return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector{
    for (id obj in self.delegates) {
        if (![[self unpackReference:obj] respondsToSelector:aSelector]) {
            return NO;
        }
    }
    return YES;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    for (id obj in self.delegates) {
        [anInvocation invokeWithTarget:[self unpackReference:obj]];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    for (id obj in self.delegates) {
      NSMethodSignature *sig =  [[self unpackReference:obj] methodSignatureForSelector:aSelector];
        if (!sig) continue;
        return sig;
    }
    return nil;
}

- (NSMutableArray *)delegates{
    if (!_delegates) {
        _delegates = @[].mutableCopy;
    }
    return _delegates;
}


- (WeakArrayObj)packetReference: (id)obj{
    __weak id weakObj = obj;
    return ^{
        return weakObj;
    };
}

- (id)unpackReference:(WeakArrayObj)arrayObj{
    return arrayObj ? arrayObj() : nil;
}

- (void)reference:(NSArray *)array{
    for (id obj in array) {
        [self.delegates addObject:[self packetReference:obj]];
    }
}
@end
