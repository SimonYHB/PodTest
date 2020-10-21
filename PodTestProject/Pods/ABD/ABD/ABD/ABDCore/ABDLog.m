
//
//  ABDLog.m
//  ABD
//
//  Created by pingan on 2019/8/12.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import "ABDLog.h"
#import "ABDManager.h"
#ifdef DEBUG
static const ABDLogLevel defaultLogLevel = ABDLogLevelAll;
#else
static const ABDLogLevel defaultLogLevel = ABDLogLevelWarning;
#endif

static id<ABDLogProtocol> _externalLog;

@interface ABDSafeLog : NSObject

+ (NSString *)getLogMessage:(NSString *)format arguments:(va_list)args;

@end

@implementation ABDLog
{
    ABDLogLevel _logLevel;
}

+ (instancetype)sharedInstance
{
    static ABDLog *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
        _sharedInstance->_logLevel = defaultLogLevel;
    });
    return _sharedInstance;
}

+ (void)setLogLevel:(ABDLogLevel)level
{
    ((ABDLog*)[self sharedInstance])->_logLevel = level;
}

+ (ABDLogLevel)logLevel
{
    return ((ABDLog*)[self sharedInstance])->_logLevel;
}

+ (NSString *)logLevelString
{
    NSDictionary *logLevelEnumToString =
    @{
      @(ABDLogLevelOff) : @"off",
      @(ABDLogLevelError) : @"error",
      @(ABDLogLevelWarning) : @"warn",
      @(ABDLogLevelInfo) : @"info",
      @(ABDLogLevelLog) : @"log",
      @(ABDLogLevelDebug) : @"debug",
      @(ABDLogLevelAll) : @"debug"
      };
    return [logLevelEnumToString objectForKey:@([self logLevel])];//! OCLINT
}

+ (void)setLogLevelString:(NSString *)levelString
{
    NSDictionary *logLevelStringToEnum =
    @{
      @"all" : @(ABDLogLevelAll),
      @"error" : @(ABDLogLevelError),
      @"warn" : @(ABDLogLevelWarning),
      @"info" : @(ABDLogLevelInfo),
      @"debug" : @(ABDLogLevelDebug),
      @"log" : @(ABDLogLevelLog)
      };
    
    [self setLogLevel:[logLevelStringToEnum[levelString] unsignedIntegerValue]];
}

+ (void)log:(ABDLogFlag)flag file:(const char *)fileName line:(NSUInteger)line message:(NSString *)message
{
    NSString *flagString;
    switch (flag) {
            case ABDLogFlagError: {
                flagString = @"error";
            }
            break;
            case ABDLogFlagWarning:
            flagString = @"warn";
            break;
            case ABDLogFlagDebug:
            flagString = @"debug";
            break;
            case ABDLogFlagLog:
            flagString = @"log";
            break;
        default:
            flagString = @"info";
            break;
    }
    
    NSString *logMessage = [NSString stringWithFormat:@"<ABD>[%@]%s:%ld, %@", flagString, fileName, (unsigned long)line, message];
    
    if ([_externalLog logLevel] & flag) {
        [_externalLog log:flag message:logMessage];
    }
    
    
    if ([ABDLog logLevel] & flag) {
        [ABDManager writeLog:logMessage type:ABDTypeCodeLog];
        NSLog(@"%@", logMessage);
    }
}

+ (void)devLog:(ABDLogFlag)flag file:(const char *)fileName line:(NSUInteger)line format:(NSString *)format, ... {
    if ([ABDLog logLevel] & flag || [_externalLog logLevel] & flag) {
        if (!format) {
            return;
        }
        NSString *flagString = @"log";
        switch (flag) {
                case ABDLogFlagError:
                flagString = @"error";
                break;
                case ABDLogFlagWarning:
                flagString = @"warn";
                break;
                case ABDLogFlagDebug:
                flagString = @"debug";
                break;
                case ABDLogFlagLog:
                flagString = @"log";
                break;
            default:
                flagString = @"info";
                break;
        }
        
        va_list args;
        va_start(args, format);
        NSString *message = @"";
        if (flag == ABDLogFlagDebug) {
            message = [ABDSafeLog getLogMessage:format arguments:args];
        } else {
            message = [[NSString alloc] initWithFormat:format arguments:args];
        }
        va_end(args);
        
        [self log:flag file:fileName line:line message:message];
    }
}

#pragma mark - External Log

+ (void)registerExternalLog:(id<ABDLogProtocol>)externalLog
{
    _externalLog = externalLog;
}

@end

#pragma mark - ABDSafeLog

static void dealWithValue(NSMutableString *result, id value, NSMutableSet *outSet);
static NSUInteger getParamCount(NSString *format, NSMutableDictionary *outDict)
{
    static NSMutableSet *possibleTwoSet = nil;
    static NSMutableSet *possibleThreeSet = nil;
    static NSMutableSet *possibleTwo = nil;
    static NSMutableSet *possibleThree = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *longArray = @[@"ld"];
        NSArray *longLongArray = @[@"lld"];
        NSDictionary *coolDict = @{@"long":longArray, @"long long":longLongArray};
        possibleTwoSet = [NSMutableSet set];
        possibleThreeSet = [NSMutableSet set];
        possibleTwo = [NSMutableSet set];
        possibleThree = [NSMutableSet set];
        for (NSString * key in coolDict.allKeys) {
            NSArray *array = coolDict[key];
            for (NSString * value in array) {
                if (value.length == 2) {
                    [possibleTwoSet addObject:value];
                    NSString *sub = [value substringWithRange:NSMakeRange(0,1)];
                    if (![possibleTwo containsObject:sub]) {
                        [possibleTwo addObject:sub];
                    }
                } else if (value.length == 3) {
                    [possibleThreeSet addObject:value];
                    NSString *sub = [value substringWithRange:NSMakeRange(0,2)];
                    if (![possibleThree containsObject:sub]) {
                        [possibleThree addObject:sub];
                    }
                }
            }
        }
    });
    
    NSUInteger paramCount = 0;
    NSUInteger formatLength = [format length];
    NSRange searchRange = NSMakeRange(0, formatLength);
    NSRange paramRange = [format rangeOfString:@"%" options:0 range:searchRange];
    
    while (paramRange.location != NSNotFound)
    {
        NSString *subString = @" ";
        NSUInteger location = paramRange.location;
        do {
            location ++;
            subString = [format substringWithRange:NSMakeRange(location, 1)];
        } while (([subString compare:@"0"] != NSOrderedAscending && [subString compare:@"9"] != NSOrderedDescending) || [subString compare:@"."] == NSOrderedSame);
        if ([possibleTwo containsObject:subString]) {
            NSString *subString3 = [format substringWithRange:NSMakeRange(location, 2)];
            if ([possibleThree containsObject:subString3]) {
                NSString *subString4 = [format substringWithRange:NSMakeRange(location, 3)];
                if ([possibleThreeSet containsObject:subString4]) {
                    subString = subString4;
                }
            } else {
                NSString *subString2 = [format substringWithRange:NSMakeRange(location, 2)];
                if ([possibleTwoSet containsObject:subString2]) {
                    subString = subString2;
                }
            }
        }
        [outDict setObject:subString forKey:@(paramCount)];//! OCLINT
        paramCount++;
        searchRange.location = paramRange.location + 1;
        searchRange.length = formatLength - searchRange.location;
        
        paramRange = [format rangeOfString:@"%" options:0 range:searchRange];
    }
    return paramCount;
}

static NSString *dealWithDictionary(NSDictionary *dict, NSMutableSet *outSet)
{
    NSMutableString *result = [NSMutableString new];
    [result appendString:@" { "];
    int i = 0;
    for (id key in dict.allKeys) {
        if ([key isKindOfClass:[NSDictionary class]] || [key isKindOfClass:[NSArray class]] || [key isKindOfClass:[NSSet class]]) {
            [result appendString:@"(invalid Dictionary key) : ( )"];
        } else {
            [result appendString:[NSString stringWithFormat:@"%@ : ", key]];
            id value = [dict objectForKey:key];//! OCLINT
            NSNumber *pointerValue = [NSNumber numberWithLong:(long)value];
            if ([outSet containsObject:pointerValue]) {
                [result appendString:@"(Found Retain Cycle!!!)"];
            } else {
                dealWithValue(result, value, outSet);
            }
        }
        i++;
        if (i < dict.allKeys.count) {
            [result appendString:@" , "];
        }
    }
    [result appendString:@" } "];
    return result;
}

static NSString *dealWithArray(NSArray *array, NSMutableSet *outSet)
{
    NSMutableString *result = [NSMutableString new];
    [result appendString:@" [ "];
    int i = 0;
    for (id value in array) {
        NSNumber *pointerValue = [NSNumber numberWithLong:(long)value];
        if ([outSet containsObject:pointerValue]) {
            [result appendString:@"(Found Retain Cycle!!!)"];
        } else {
            dealWithValue(result, value, outSet);
        }
        i++;
        if (i < array.count) {
            [result appendString:@" , "];
        }
    }
    [result appendString:@" ] "];
    return result;
}

static NSString *dealWithSet(NSSet *set, NSMutableSet *outSet)
{
    NSMutableString *result = [NSMutableString new];
    [result appendString:@" ( "];
    int i = 0;
    for (id value in set) {
        NSNumber *pointerValue = [NSNumber numberWithLong:(long)value];
        if ([outSet containsObject:pointerValue]) {
            [result appendString:@"(Found Retain Cycle!!!)"];
        } else {
            dealWithValue(result, value, outSet);
        }
        i++;
        if (i < set.count) {
            [result appendString:@" , "];
        }
    }
    [result appendString:@" ) "];
    return result;
}

static void dealWithValue(NSMutableString *result, id value, NSMutableSet *outSet)
{
    NSNumber *pointerValue = [NSNumber numberWithLong:(long)value];
    if (pointerValue.longValue > 100000) {
        [outSet addObject:pointerValue];
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSString *tempString = dealWithArray((NSArray *)value, outSet);
        [result appendString:tempString];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        [result appendString:dealWithDictionary((NSDictionary *)value, outSet)];
    } else if ([value isKindOfClass:[NSSet class]]) {
        [result appendString:dealWithSet((NSSet *)value, outSet)];
    } else {
        [result appendString:[NSString stringWithFormat:@"%@", value]];
    }
}

@implementation ABDSafeLog

+ (NSString *)getLogMessage:(NSString *)format arguments:(va_list)args
{
    NSMutableString *mutableFormat = [NSMutableString stringWithString:format];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSUInteger count = getParamCount(format, dict);
    NSMutableArray<NSString *> *replacedDict = [NSMutableArray array];
    for (NSUInteger i = 0; i < count; i++) {
        if ([dict[@(i)] isEqualToString:@"@"]) {
            NSMutableSet *outSet = [NSMutableSet set];
            __unsafe_unretained id obj = va_arg(args, id);
            NSString *output = @"";
            if (obj) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    output = dealWithDictionary((NSDictionary *)obj, outSet);
                } else if ([obj isKindOfClass:[NSArray class]]) {
                    output = dealWithArray((NSArray *)obj, outSet);
                } else if ([obj isKindOfClass:[NSSet class]]) {
                    output = dealWithSet((NSSet *)obj, outSet);
                } else {
                    output = [NSString stringWithFormat:@"%@", obj];
                }
            }
            [replacedDict addObject:output];
        } else {
            NSString *logFormat = dict[@(i)];
            if (logFormat.length == 1) {
#define LEN 2
                char tempChar[LEN];
                memset(tempChar, 0, LEN);
                [logFormat getCString:tempChar maxLength:LEN encoding:NSASCIIStringEncoding];
                switch(tempChar[0]) {
                        case '%':
                        case 'c':
                        va_arg(args, int);
                        break;
                        case 'd':
                        case 'D':
                        va_arg(args, int);
                        break;
                        case 'f':
                        case 'F':
                        va_arg(args, double);
                        break;
                        case 'C':
                        va_arg(args, int);
                        break;
                        case 's':
                        va_arg(args, char *);
                        break;
                        case 'S':
                        va_arg(args, unichar *);
                        break;
                        case 'p':
                        va_arg(args, void *);
                        break;
                    default:
                        va_arg(args, void *);
                        break;
                }
            } else {
                static NSDictionary *map;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    map = @{
                            @"ld":@"long", \
                            @"lld":@"long long", \
                            };
                });
                NSString *type = map[dict[@(i)]];
                if ([type isEqualToString:@"long"]) {
                    va_arg(args, long);
                } else if ([type isEqualToString:@"long long"]) {
                    va_arg(args, long long);
                }
            }
        }
    }
    NSString *prefix = @"#$~";
    NSString *suffix = @"~$#";
    NSString *replace = [NSString stringWithFormat:@"%@%%p%@", prefix, suffix];
    [mutableFormat replaceOccurrencesOfString:@"%@" withString:replace options:NSLiteralSearch range:NSMakeRange(0, mutableFormat.length)];
    NSMutableString *result = [[NSMutableString alloc] initWithFormat:mutableFormat arguments:args];
    int j = 0;
    NSRange range, range1, range2;
    range1 = [result rangeOfString:prefix options:NSLiteralSearch];
    range2 = [result rangeOfString:suffix options:NSLiteralSearch];
    range = NSMakeRange(range1.location, range2.location+range2.length - range1.location);
    while(range1.length>0 && range2.length>0) {
        [result replaceCharactersInRange:range withString:replacedDict[j++]];
        range1 = [result rangeOfString:prefix options:NSLiteralSearch];
        range2 = [result rangeOfString:suffix options:NSLiteralSearch];
        range = NSMakeRange(range1.location, range2.location+range2.length - range1.location);
    }
    return result;
}

@end

