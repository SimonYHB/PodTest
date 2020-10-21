//
//  ABDNetManager.h
//  ABD-iOS
//
//  Created by 刘贺松 on 2019/3/29.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ABDNetManager : NSObject

/**
 设置上传的URL地址信息, 在ABD中默认的上传 CAT Mobile

 @param uploadUrl 上传的URL路径
 */
+ (void)setUploadUrl:(NSString *)uploadUrl;

/**
 上传ABD 日志信息

 @param appId  分配给宿主的App 唯一表示符号
 @param deviceId 设备的唯一标识符号
 @param orderId 下发的回捞orderId
 @param dateStr 回捞的日期
 @param forceUpload 是否强制上传
 @param source 主动上传的入口信息
 @param extraInfo 额外的信息
 */
+ (void)uploadLogsAppId:(NSString *)appId deviceId:(NSString *)deviceId orderId:(NSString *)orderId dateStr:(NSString *)dateStr forceUpload:(BOOL)forceUpload source:(NSString *)source extraInfo:(NSString *)extraInfo;

/**
 检查本地失败的上传任务
 */
+ (void)checkLocalFailTask;

/**
 检查任务是否过期

 @param dateStr 检查日期
 @return 是否过期
 */
+ (BOOL)isExpiredInfo:(NSString *)dateStr;

@end

NS_ASSUME_NONNULL_END
