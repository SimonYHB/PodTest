//
//  ABDManager.h
//  ABD-iOS
//
//  Created by 刘贺松 on 2019/3/12.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger
{
    ABDTypeAction     = 0, //行为日志
    ABDTypeBuried     = 1, //埋点日志
    ABDTypeCodeLog    = 2, //代码日志
    ABDTypeNetworkLog = 3, //网络日志
    ABDTypePushLog    = 4, //推送日志
    ABDTypeCrashLog   = 5, //崩溃日志
} ABDLogType; // 如需新增日志类型，需要在ABD后台申请注册

// ABD主动上传回调
typedef void (^ABDUploadResult)(NSInteger statusCode);
@interface ABDManager : NSObject

/**
 ABDManager 的初始化方法，首先设置设备的唯一表示符号

 @param appId 对应宿主APP的appId
 @param deviceId 对应的设备的设备ID
 */
+ (void)setAppId:(NSString *)appId deviceId:(NSString *)deviceId;

/**
 是否输出日志到控制台
 @param useASL 是否输出
 */
+ (void)canUseASL:(BOOL)useASL;

/**
 设置上传的URL，该方法为option的，ABD默认会传到CAT 后台

 @param uploadUrl 上传的URL
 */
+ (void)setUploadUrl:(NSString *)uploadUrl;

/**
 写日志
 @param type 日志的类型
 @param log 日志的内容
 */
+ (void)writeLog:(NSString *)log type:(ABDLogType)type;

/**
 写日志

 @param log 日志内容
 @param type 日志类型
 @param extra 额外的信息
 @param tag  日志的tag 标识
 */
+ (void)writeLog:(NSString *)log type:(ABDLogType)type extra:(NSString *)extra tag:(NSString *)tag;

/**
 主动上传今日ABD的信息

 @param source 信息的来源
 @param extraInfo 额外的信息：例如图片截图的图片信息
 @param callBack 日志上传返回的状态码
 成功：返回 1000
 网络检测失败：返回-1001
 写库回调失败，返回:-1002
 */
+ (void)uploadLogsSource:(NSString *)source extraInfo:(NSArray *)extraInfo callBack:(ABDUploadResult)callBack;

/**
主动上传指定日期的ABD信息

@param orderId 传nil
@param forceUpload 传NO
@param dateStr 指定日志，格式：2020-03-21
@param source 信息的来源
@param extraInfo 额外的信息：例如图片截图的图片信息
@param callBack 日志上传返回的状态码
成功：返回 1000
网络检测失败：返回-1001
写库回调失败，返回:-1002
*/
+ (void)uploadOrderId:(NSString *)orderId forceUpload:(BOOL)forceUpload dateStr:(NSString *)dateStr source:(NSString *)source extraInfo:(NSString *)extraInfo callBack:(ABDUploadResult)callBack;
/**
 推送回捞指定日期的日志

 @param orderId 回捞id
 @param forceUpload 是否强制回捞
 @param dateStr 回捞的日期 "2019-09-12"
 */
+ (void)uploadOrderId:(NSString *)orderId forceUpload:(BOOL)forceUpload dateStr:(NSString *)dateStr;

/**
 获取本地的日志文件信息
 @return 所有本地的日志文件信息
 */
+ (NSDictionary *)allLogFileInfo;

/**
 @return 返回当前设备的DeviceId
 */
+ (NSString *)getCurrentDeviceId;

/**
 @return 返回当前的APPId
 */
+ (NSString *)getCurrentAppId;

@end

NS_ASSUME_NONNULL_END
