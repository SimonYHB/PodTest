/*
 * Copyright (c) 2019,平安
 */

#import <Foundation/Foundation.h>

#define ABD_Encrypt_Verison @"1"

#define ADB_SDK_Version @"1.1.0"

#define ABD_Expired_Time 7 * 24 * 60 * 60 * 1000
#define ABD_MAX_Size 10 * 1024 * 1024

extern void ABDCoreUseASL(BOOL b);

/**
 返回文件路径
 @param  filePath nil时表示文件不存在
 */
typedef void (^ABDCoreFilePathBlock)(NSString *_Nullable filePath);

/**
 ABDCore初始化
 @param aes_key16 16位aes加密key
 @param aes_iv16  16位aes加密iv
 @param max_file  日志文件最大大小，超过该大小后日志将不再被写入，单位：byte。
 */
extern void ABDCoreInit(NSData *_Nonnull aes_key16, NSData *_Nonnull aes_iv16, uint64_t max_file);

/**
 记录ABDCore日志
 @param type 日志类型
 @param log  日志字符串
 @brief
 用例：
 ABDCoreLog(1, @"this is a test");
 */
extern void ABDCoreLog(NSUInteger type, NSString *_Nonnull log,NSString *  _Nullable extra,NSString * _Nullable tag);

//extern void ABDCoreLog(NSUInteger type, NSString *_Nonnull log);
/**
 将日志全部输出到控制台的开关，默认NO
 @param b 开关
 */
extern void ABDCoreUseASL(BOOL b);

/**
 立即写入日志文件
 */
extern void ABDCoreFlash(void);

/**
 日志信息输出开关，默认NO
 @param b 开关
 */
extern void ABDCorePrintClibLog(BOOL b);

/**
 清除本地所有日志
 */
extern void ABDCoreClearAllLogs(void);

/**
 返回本地所有文件名及大小(单位byte)
 @return @{@"2018-11-21":@"110"}
 */
extern NSDictionary *_Nullable ABDCoreAllFilesInfo(void);

/**
 根据日期获取上传日志的文件路径，异步方式！
 @param date 日志日期 格式："2018-11-21"
 @param filePathBlock 回调返回文件路径，在主线程中回调
 */
extern void ABDCoreUploadFilePath(NSString *_Nonnull date, ABDCoreFilePathBlock _Nonnull filePathBlock);

/**
 返回指定日期的文件路径
 @param date 日志日期 格式："2018-11-21"
 @return 文件的路径地址
 */
extern NSString * _Nonnull ABDCoreFilePath(NSString * _Nullable date);

/**
 返回今天日期
 @return @"2018-11-21"
 */
extern NSString *_Nonnull ABDCoreTodaysDate(void);
