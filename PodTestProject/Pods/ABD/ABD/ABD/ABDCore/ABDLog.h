//
//  ABDLog.h
//  ABD
//
//  Created by pingan on 2019/8/12.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ABDLogLevel ABDLogLevel

typedef NS_ENUM(NSInteger, ABDLogFlag)
{
    ABDLogFlagError      = 1 << 0,
    ABDLogFlagWarning    = 1 << 1,
    ABDLogFlagInfo       = 1 << 2,
    ABDLogFlagLog        = 1 << 3,
    ABDLogFlagDebug      = 1 << 4
};

/**
 *  使用日志级别来过滤日志
 */
typedef NS_ENUM(NSUInteger, ABDLogLevel)
{
    ABDLogLevelOff       = 0,
    ABDLogLevelError     = ABDLogFlagError,
    ABDLogLevelWarning   = ABDLogLevelError | ABDLogFlagWarning,
    ABDLogLevelInfo      = ABDLogLevelWarning | ABDLogFlagInfo,
    ABDLogLevelLog       = ABDLogFlagLog | ABDLogLevelInfo,
    ABDLogLevelDebug     = ABDLogLevelLog | ABDLogFlagDebug,
    ABDLogLevelAll       = NSUIntegerMax
};

/**
 *  外部日志协议,用于输出日志
 */
@protocol ABDLogProtocol <NSObject>

@required

/**
 * 日志级别
 */
- (ABDLogLevel)logLevel;

- (void)log:(ABDLogFlag)flag message:(NSString *)message;

@end

@interface ABDLog : NSObject

+ (ABDLogLevel)logLevel;

+ (void)setLogLevel:(ABDLogLevel)level;

+ (NSString *)logLevelString;

+ (void)setLogLevelString:(NSString *)levelString;

+ (void)log:(ABDLogFlag)flag file:(const char *)fileName line:(NSUInteger)line message:(NSString *)message;

+ (void)devLog:(ABDLogFlag)flag file:(const char *)fileName line:(NSUInteger)line format:(NSString *)format, ... NS_FORMAT_FUNCTION(4,5);

+ (void)registerExternalLog:(id<ABDLogProtocol>)externalLog;

@end

#define ABD_FILENAME (strrchr(__FILE__, '/') ? strrchr(__FILE__, '/') + 1 : __FILE__)

#define ABD_LOG(flag, fmt, ...)          \
do {                                    \
[ABDLog devLog:flag                     \
file:ABD_FILENAME              \
line:__LINE__                 \
format:(fmt), ## __VA_ARGS__];  \
} while(0)

extern void _GNLogObjectsImpl(NSString *severity, NSArray *arguments);

#define ABDLog(format,...)               ABD_LOG(ABDLogFlagLog, format, ##__VA_ARGS__)
#define ABDLogDebug(format, ...)         ABD_LOG(ABDLogFlagDebug, format, ##__VA_ARGS__)
#define ABDLogInfo(format, ...)          ABD_LOG(ABDLogFlagInfo, format, ##__VA_ARGS__)
#define ABDLogWarning(format, ...)       ABD_LOG(ABDLogFlagWarning, format ,##__VA_ARGS__)
#define ABDLogError(format, ...)         ABD_LOG(ABDLogFlagError, format, ##__VA_ARGS__)

