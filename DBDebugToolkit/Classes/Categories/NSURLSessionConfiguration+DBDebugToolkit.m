// The MIT License
//
// Copyright (c) 2016 Dariusz Bukowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <objc/runtime.h>
#import "NSURLSessionConfiguration+DBDebugToolkit.h"
#import "DBURLProtocol.h"

@implementation NSURLSessionConfiguration (DBDebugToolkit)

#pragma mark - Method Swizzling

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self exchangeMethodsWithOriginalSelector:@selector(defaultSessionConfiguration)
                              andSwizzledSelector:@selector(db_defaultSessionConfiguration)];
        [self exchangeMethodsWithOriginalSelector:@selector(ephemeralSessionConfiguration)
                              andSwizzledSelector:@selector(db_ephemeralSessionConfiguration)];
    });
}

+ (void)exchangeMethodsWithOriginalSelector:(SEL)originalSelector andSwizzledSelector:(SEL)swizzledSelector {
    Class class = object_getClass((id)self);
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (instancetype)db_defaultSessionConfiguration {
    NSURLSessionConfiguration *defaultSessionConfiguration = [self db_defaultSessionConfiguration];
    NSMutableArray *originalProtocols = [NSMutableArray arrayWithArray:defaultSessionConfiguration.protocolClasses];
    [originalProtocols insertObject:[DBURLProtocol class] atIndex:0];
    defaultSessionConfiguration.protocolClasses = originalProtocols;
    return defaultSessionConfiguration;
}

+ (instancetype)db_ephemeralSessionConfiguration {
    NSURLSessionConfiguration *ephemeralSessionConfiguration = [self db_ephemeralSessionConfiguration];
    NSMutableArray *originalProtocols = [NSMutableArray arrayWithArray:ephemeralSessionConfiguration.protocolClasses];
    [originalProtocols insertObject:[DBURLProtocol class] atIndex:0];
    ephemeralSessionConfiguration.protocolClasses = originalProtocols;
    return ephemeralSessionConfiguration;
}

@end
