/*
 * Copyright (c) 2019,平安
 */

#import "ABDCore.h"
#import <sys/time.h>
#include <sys/mount.h>
#include "cabd_core.h"
#import "ABDLog.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif



BOOL ABDUSEASL = NO;
NSData *__AES_KEY;
NSData *__AES_IV;
uint64_t __max_file;

@interface ABDCore : NSObject
{
    NSTimeInterval _lastCheckFreeSpace;
}
@property (nonatomic, copy) NSString *lastLogDate;

#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t abdCoreQueue;
#else
@property (nonatomic, assign) dispatch_queue_t abdCoreQueue;
#endif

+ (instancetype)shareIntance;
- (void)writeLog:(NSString *)log logType:(NSUInteger)type extra:(NSString *)extra tag:(NSString *)tag;
- (void)clearLogs;
+ (NSDictionary *)allFilesInfo;
+ (NSString *)currentDate;
- (void)flash;
- (void)filePathForDate:(NSString *)date block:(ABDCoreFilePathBlock)filePathBlock;
- (NSString *)filePathForDate:(NSString *)date;
@end

void ABDCoreInit(NSData *_Nonnull aes_key16, NSData *_Nonnull aes_iv16, uint64_t max_file)
{
    __AES_KEY  = aes_key16;
    __AES_IV   = aes_iv16;
    __max_file = max_file;
    [ABDCore shareIntance];
}


void ABDCoreLog(NSUInteger type, NSString *_Nonnull log,NSString * extra,NSString *tag)
{
    [[ABDCore shareIntance] writeLog:log logType:type extra:extra tag:tag];
    
}

void ABDCoreUseASL(BOOL b)
{
    ABDUSEASL = b;
}

void ABDCorePrintClibLog(BOOL b)
{
    cabd_debug(!!b);
}

void ABDCoreClearAllLogs(void)
{
    [[ABDCore shareIntance] clearLogs];
}

NSDictionary *_Nullable ABDCoreAllFilesInfo(void)
{
    return [ABDCore allFilesInfo];
}

void ABDCoreUploadFilePath(NSString *_Nonnull date, ABDCoreFilePathBlock _Nonnull filePathBlock)
{
    [[ABDCore shareIntance] filePathForDate:date block:filePathBlock];
}

NSString *_Nonnull ABDCoreFilePath(NSString *date)
{
    return [[ABDCore shareIntance] filePathForDate:date];
}
void ABDCoreFlash(void)
{
    [[ABDCore shareIntance] flash];
}

NSString *_Nonnull ABDCoreTodaysDate(void)
{
    return [ABDCore currentDate];
}

@implementation ABDCore
+ (instancetype)shareIntance
{
    static ABDCore *instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        instance = [[ABDCore alloc] init];
    });
    return instance;
}

- (nonnull instancetype)init
{
    if (self = [super init]) {
        _abdCoreQueue = dispatch_queue_create("com.pingan.Canna", DISPATCH_QUEUE_SERIAL);
        dispatch_async(self.abdCoreQueue, ^{
            [self initAndOpenCLib];
            [self addNotification];
            [self reTemFile];
            [self cleanExpiredFile];
        });
    }
    return self;
}

- (void)initAndOpenCLib
{
    if (__AES_IV == nil || __AES_KEY == nil)
    {
        ABDLogWarning(@"aes_key || aes_iv is nil!!!,Please use llogInit() to set the key.");
        return;
    }

    const char *path = [ABDCore ABDCoreLogDirectory].UTF8String;

    const char *aeskey = (const char *)[__AES_KEY bytes];
    const char *aesiv  = (const char *)[__AES_IV bytes];
    cabd_init(path, path, (int)__max_file, aeskey, aesiv);
    NSString *today = [ABDCore currentDate];
//    NSString * today = @"2019-09-19_2";
    cabd_open((char *)today.UTF8String);
    __AES_KEY = nil;
    __AES_IV  = nil;
}

- (void)writeLog:(NSString *)log logType:(NSUInteger)type extra:(NSString *)extra tag:(NSString *)tag
{
    if (log.length == 0) {
        return;
    }
    NSTimeInterval localTime = [[NSDate date] timeIntervalSince1970] * 1000;
//    NSString *threadName = [[NSThread currentThread] name];
    NSInteger threadNum  = [self getThreadNum];
    BOOL threadIsMain    = [[NSThread currentThread] isMainThread];
//    char *threadNameC    = threadName ? (char *)threadName.UTF8String : "";
    
    if (ABDUSEASL) {
        [self printfLog:log type:type];
    }

    if (![self hasFreeSpece]) {
        return;
    }

    dispatch_async(self.abdCoreQueue, ^{
        NSString *today = [ABDCore currentDate];
        if (self.lastLogDate && ![self.lastLogDate isEqualToString:today]) {
            // 日期变化，立即写入日志文件
            cabd_flush();
            cabd_open((char *)today.UTF8String);
        }
        self.lastLogDate = today;
        cabd_write((int)type, (char *)log.UTF8String, (long long)localTime, (long long)threadNum, (int)threadIsMain, (char *)extra.UTF8String, (char *)tag.UTF8String);
    });
}

- (void)flash
{
    dispatch_async(self.abdCoreQueue, ^{
        [self flashInQueue];
    });
}

- (void)flashInQueue
{
    cabd_flush();
}

- (void)clearLogs
{
    dispatch_async(self.abdCoreQueue, ^{
        NSArray *array = [ABDCore localFilesArray];
        NSError *error = nil;
        BOOL ret;
        for (NSString *name in array) {
            NSString *path = [[ABDCore ABDCoreLogDirectory] stringByAppendingPathComponent:name];
            ret            = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
    });
}

- (BOOL)hasFreeSpece
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now > (_lastCheckFreeSpace + 60)) {
        _lastCheckFreeSpace = now;
        // 每隔至少1分钟，检查一下剩余空间
        long long freeDiskSpace = [self freeDiskSpaceInBytes];
        if (freeDiskSpace <= 5 * 1024 * 1024) {
            // 剩余空间不足5m时，不再写入
            return NO;
        }
    }
    return YES;
}

- (long long)freeDiskSpaceInBytes
{
    struct statfs buf;
    long long freespace = -1;
    if (statfs("/var", &buf) >= 0) {
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    return freespace;
}

- (NSInteger)getThreadNum
{
    NSString *description = [[NSThread currentThread] description];
    NSRange beginRange    = [description rangeOfString:@"{"];
    NSRange endRange      = [description rangeOfString:@"}"];

    if (beginRange.location == NSNotFound || endRange.location == NSNotFound)
        return -1;

    NSInteger length = endRange.location - beginRange.location - 1;
    if (length < 1) {
        return -1;
    }

    NSRange keyRange = NSMakeRange(beginRange.location + 1, length);

    if (keyRange.location == NSNotFound) {
        return -1;
    }

    if (description.length > (keyRange.location + keyRange.length)) {
        NSString *keyPairs     = [description substringWithRange:keyRange];
        NSArray *keyValuePairs = [keyPairs componentsSeparatedByString:@","];
        for (NSString *keyValuePair in keyValuePairs) {
            NSArray *components = [keyValuePair componentsSeparatedByString:@"="];
            if (components.count) {
                NSString *key = components[0];
                key           = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (([key isEqualToString:@"num"] || [key isEqualToString:@"number"]) && components.count > 1) {
                    return [components[1] integerValue];
                }
            }
        }
    }
    return -1;
}

- (void)printfLog:(NSString *)log type:(NSUInteger)type
{
    static time_t dtime = -1;
    if (dtime == -1) {
        time_t tm;
        time(&tm);
        struct tm *t_tm;
        t_tm  = localtime(&tm);
        dtime = t_tm->tm_gmtoff;
    }
    struct timeval time;
    gettimeofday(&time, NULL);
    int secOfDay    = (time.tv_sec + dtime) % (3600 * 24);
    int hour        = secOfDay / 3600;
    int minute      = secOfDay % 3600 / 60;
    int second      = secOfDay % 60;
    int millis      = time.tv_usec / 1000;
    NSString *str   = [[NSString alloc] initWithFormat:@"%02d:%02d:%02d.%03d [%lu] %@\n", hour, minute, second, millis, (unsigned long)type, log];
    const char *buf = [str cStringUsingEncoding:NSUTF8StringEncoding];
    printf("%s", buf);
}
#pragma mark - notification
- (void)addNotification
{
    // App Extension
    if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) {
        return;
    }
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
#else
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:NSApplicationWillBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:NSApplicationDidResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:NSApplicationWillTerminateNotification object:nil];
#endif
}

- (void)appWillResignActive
{
    [self flash];
}

- (void)appDidEnterBackground
{
    [self flash];
}

- (void)appWillEnterForeground
{
    [self flash];
}

- (void)appWillTerminate
{
    [self flash];
}

- (void)filePathForDate:(NSString *)date block:(ABDCoreFilePathBlock)filePathBlock
{
    NSString *uploadFilePath = [self filePathForDate:date];

    if (uploadFilePath.length) {
        if ([[ABDCore currentDate] containsString:date]) {
            dispatch_async(self.abdCoreQueue, ^{
                [self todayFilePatch:filePathBlock];
            });
            return;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        filePathBlock(uploadFilePath);
    });
}
- (NSString *)filePathForDate:(NSString *)date
{
    if (date.length <= 0) {
        return nil;
    }
    NSString *filePath = nil;
    NSArray *allFiles = [ABDCore localFilesArray];
    if ([date containsString:@"_"]) {
        if ([allFiles containsObject:date]) {
            filePath = [ABDCore logFilePath:date];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                return filePath;
            }
        }
    }else{
        NSMutableArray * arr = [[NSMutableArray alloc]init];
        for (NSString * dateStr in allFiles) {
            if ([dateStr containsString:date]) {
                [arr addObject:dateStr];
            }
        }
        filePath = [ABDCore logFilePath:arr.lastObject];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            return filePath;
        }
    }
    return nil;
}

- (void)todayFilePatch:(ABDCoreFilePathBlock)filePathBlock
{
    [self flashInQueue];
    NSString *uploadFilePath = [ABDCore uploadFilePath:[ABDCore currentDate]];
    NSString *filePath       = [ABDCore logFilePath:[ABDCore currentDate]];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:uploadFilePath error:&error];
    if (![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:uploadFilePath error:&error]) {
        uploadFilePath = nil;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        filePathBlock(uploadFilePath);
    });
}

- (void)reTemFile
{
    NSArray *allFiles = [ABDCore localFilesArray];
    for (NSString *f in allFiles) {
        if ([f hasSuffix:@".temp"]) {
            NSString *filePath = [ABDCore logFilePath:f];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSDictionary *)allFilesInfo
{
    NSArray *allFiles            = [ABDCore localFilesArray];
    NSString *dateFormatString   = @"yyyy-MM-dd";
    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    for (NSString *file in allFiles) {
        if ([file pathExtension].length > 0) {
            continue;//! OCLINT
        }
        NSString *dateString          = [file substringToIndex:dateFormatString.length];
        unsigned long long gzFileSize = [ABDCore fileSizeAtPath:[self logFilePath:file]];
        NSString *size                = [NSString stringWithFormat:@"%llu", gzFileSize];
        [infoDic setObject:size forKey:dateString];
    }
    return infoDic;
}

#pragma mark - file
+ (NSString *)uploadFilePath:(NSString *)date
{
    return [[self ABDCoreLogDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.temp", date]];
}
+ (NSString *)logFilePath:(NSString *)date
{
    return [[ABDCore ABDCoreLogDirectory] stringByAppendingPathComponent:[ABDCore logFileName:date]];
}

+ (NSString *)logFileName:(NSString *)date
{
    return [NSString stringWithFormat:@"%@", date];
}

+ (unsigned long long)fileSizeAtPath:(NSString *)filePath
{
    if (filePath.length == 0) {
        return 0;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist               = [fileManager fileExistsAtPath:filePath];
    if (isExist) {
        return [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
    } else {
        return 0;
    }
}

+ (NSArray *)localFilesArray
{
    return [[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self ABDCoreLogDirectory] error:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] '-'"]] sortedArrayUsingSelector:@selector(compare:)]; //[c]不区分大小写 , [d]不区分发音符号即没有重音符号 , [cd]既不区分大小写，也不区分发音符号。
}

+ (NSString *)currentDate
{
    NSString *key                   = @"CANNA_CURRENTDATE";//! OCLINT
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter  = [dictionary objectForKey:key];
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dictionary setObject:dateFormatter forKey:key];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    NSString * dateStr = [dateFormatter stringFromDate:[NSDate new]];
    return [NSString stringWithFormat:@"%@_%@",dateStr,ABD_Encrypt_Verison];
}

- (void)cleanExpiredFile
{
    NSArray *allFiles = [ABDCore localFilesArray];

    NSTimeInterval currentTimeInterval = [NSDate new].timeIntervalSince1970;
    NSDateFormatter *dateFormatter     = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];

    for (NSString *fileStr in allFiles) {
        NSString * fileS = [fileStr componentsSeparatedByString:@"_"].firstObject;
        NSDate *data = [dateFormatter dateFromString:fileS];
        if ((currentTimeInterval - data.timeIntervalSince1970) * 1000 > ABD_Expired_Time) {
            NSString *filePath = [ABDCore logFilePath:fileStr];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        }
    }
}

+ (NSString *)ABDCoreLogDirectory
{
    static NSString *dir = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"ABDCoreLoggerv3"];
    });
    return dir;
}
@end
