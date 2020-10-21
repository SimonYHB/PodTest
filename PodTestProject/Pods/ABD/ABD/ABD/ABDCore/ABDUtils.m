//
//  ABDUtils.m
//  ABD-iOS
//
//  Created by 刘贺松 on 2019/3/15.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import "ABDUtils.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation ABDUtils

//对二进制数据进行MD5编码
+ (NSString *)encode_md5_data:(NSData *)data
{
    if ([data length] <= 0) {
        return nil;
    }

    const char *input = [data bytes];
    unsigned char output[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (uint32_t)[data length], output); //! OCLINT

    NSString *resultStr = [NSString stringWithFormat:
                                      @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                                      output[0], output[1], output[2], output[3],
                                      output[4], output[5], output[6], output[7],
                                      output[8], output[9], output[10], output[11],
                                      output[12], output[13], output[14], output[15]];

    return [resultStr lowercaseString];
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

+ (NSDate *)dateFromString:(NSString *)dateStr
{
    NSString *key                   = @"ABD_CURRENTDATE";
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter  = [dictionary objectForKey:key];
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dictionary setObject:dateFormatter forKey:key]; //! OCLINT
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return [dateFormatter dateFromString:dateStr];
}
+ (NSDate *)dateFrom:(NSTimeInterval)timeInterVale
{
    NSTimeInterval time = timeInterVale / 1000;
    return [NSDate dateWithTimeIntervalSince1970:time];
}
+ (NSTimeInterval)timeInterValFromDate:(NSDate *)date
{
    return date.timeIntervalSince1970 * 1000;
}
+ (NSTimeInterval)timeInterValFromDateStr:(NSString *)dateStr
{
    return [self dateFromString:dateStr].timeIntervalSince1970 * 1000;
}
+ (NSString *)stringFromDate:(NSDate *)date
{
    NSString *key                   = @"ABD_CURRENTDATE";
    NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter  = [dictionary objectForKey:key];
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dictionary setObject:dateFormatter forKey:key]; //! OCLINT
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return [dateFormatter stringFromDate:date];
}

+(NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval{
    
    return [self stringFromDate:[self dateFrom:timeInterval]];
}


+ (NSString *)ObjectToJSONString:(id)object
{
    if (object == nil) {
        return @"";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    if (!data) {
        return nil;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonString;
}
@end
