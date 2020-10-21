//
//  ABDUtils.h
//  ABD-iOS
//
//  Created by 刘贺松 on 2019/3/15.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ABDUtils : NSObject

/**
 对Data数据进行MD5加密
 @param data data 数据文件
 @return MD5字符串
 */
+ (NSString *)encode_md5_data:(NSData *)data;

/**
 获取指定文件的URL的大小
 @param filePath 文件地址信息
 @return 文件大小
 */
+ (unsigned long long)fileSizeAtPath:(NSString *)filePath;

/**
 "yyyy-MM-dd" 类型的日期字符串转 NSDate
 @param dateStr 日期字符串
 @return Date 数据
 */
+ (NSDate *)dateFromString:(NSString *)dateStr;

/**
 根据时间戳返回对应的日期

 @param timeInterVale 时间戳 毫秒级别
 @return 日期
 */
+ (NSDate *)dateFrom:(NSTimeInterval)timeInterVale;

/**
 根据日期返回对应的时间戳

 @param date 日期
 @return 时间戳 毫秒级别
 */
+ (NSTimeInterval)timeInterValFromDate:(NSDate *)date;

/**
 根据日期字符串返回对应的时间戳

 @param dateStr 日期字符串 "yyyy-MM-dd" 类型
 @return 时间戳 毫秒级别
 */
+(NSTimeInterval)timeInterValFromDateStr:(NSString *)dateStr;


/**
 NSDate 转 "yyyy-MM-dd" 的字符串
 
 @return date 日期字符串
 */
+(NSString*)stringFromDate:(NSDate *)date;

/**
 根据时间戳 返回对应的日期字符串

 @param timeInterval 时间戳 毫秒级
 @return 日期字符串
 */
+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval;


/**
 object 转换为JSONString

 @param object 需要转换的object
 @return JSON字符串
 */
+ (NSString *)ObjectToJSONString:(id)object;
@end

NS_ASSUME_NONNULL_END
