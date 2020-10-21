//
//  ABDManager.m
//  ABDemo
//
//  Created by 刘贺松 on 2019/3/12.
//  Copyright © 2019 刘贺松. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ABDManager.h"
#import "ABDCore.h"
#import "ABDLog.h"
#import "ABDUtils.h"
#import "ABDNetManager.h"
#import "ABDReachability.h"
#import "ABDNetCheckService.h"


@interface ABDManager ()

@property (nonatomic, copy) NSString *deviceId; // 当前的宿主的设备ID
@property (nonatomic, copy) NSString *appId;    // 当前的宿主的appId

@end

@implementation ABDManager

+ (instancetype)shareInstance
{
    static ABDManager *instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        instance = [[ABDManager alloc] init];
    });
    return instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
         [[ABDReachability sharedManager] startMonitoring];
    }
    return self;
}

#pragma mark -ABD设置相关的信息
+ (void)setAppId:(NSString *)appId deviceId:(NSString *)deviceId
{
    if (appId == nil || appId.length <= 0) {
        return;
    }
    if (deviceId == nil || deviceId.length <= 0) {
        return;
    }
    [ABDManager shareInstance].deviceId = deviceId;
    [ABDManager shareInstance].appId    = appId;
    [self initABDCore];
    [self reuploadFailLogData];
}
+ (void)initABDCore
{
    NSData * data = [[NSString stringWithFormat:@"%@%@",[ABDManager shareInstance].deviceId,[ABDManager shareInstance].appId] dataUsingEncoding:NSUTF8StringEncoding];
    NSString * string = [ABDUtils encode_md5_data:data];
    NSString * keyStr = [string substringToIndex:(string.length / 2)];
    NSString * ivStr = [string substringFromIndex:(string.length / 2)];
    
    NSData *keydata   = [keyStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivdata    = [ivStr dataUsingEncoding:NSUTF8StringEncoding];
    uint64_t file_max = ABD_MAX_Size; // 默认暂定每日存储的日志为10M
    ABDCoreInit(keydata, ivdata, file_max);
    
}

+ (void)canUseASL:(BOOL)useASL
{
    ABDCoreUseASL(useASL);
}

+ (void)setUploadUrl:(NSString *)uploadUrl
{
    if (uploadUrl.length > 0) {
        [ABDNetManager setUploadUrl:uploadUrl];
    }
}

#pragma mark -ABD 日志写入的方法
+ (void)writeLog:(NSString *)log type:(ABDLogType)type
{
    if ([ABDManager shareInstance].deviceId.length > 0 && [ABDManager shareInstance].appId.length > 0) {
        ABDCoreLog(type, log, NULL, NULL);
    }
}

+ (void)writeLog:(NSString *)log type:(ABDLogType)type extra:(NSString *)extra tag:(NSString *)tag
{
    if ([ABDManager shareInstance].deviceId.length >0 &&[ABDManager shareInstance].appId.length > 0) {
        ABDCoreLog(type, log, extra, tag);
    }
}

#pragma mark-- 上传日志信息
+ (void)uploadLogsSource:(NSString *)source extraInfo:(NSArray *)extraInfo callBack:(ABDUploadResult)callBack{
    [self uploadOrderId:nil forceUpload:NO dateStr:[self getCurrentTime] source:source extraInfo:[ABDUtils ObjectToJSONString:extraInfo] callBack:callBack];
}

+ (void)uploadOrderId:(NSString *)orderId forceUpload:(BOOL)forceUpload dateStr:(NSString *)dateStr
{
    NSString *dateS = [NSString stringWithFormat:@"%@_%@", dateStr, ABD_Encrypt_Verison];
    [self uploadOrderId:orderId forceUpload:forceUpload dateStr:dateS source:nil extraInfo:nil callBack:nil];
}

+ (void)uploadOrderId:(NSString *)orderId forceUpload:(BOOL)forceUpload dateStr:(NSString *)dateStr source:(NSString *)source extraInfo:(NSString *)extraInfo callBack:(ABDUploadResult)callBack
{
    NSString *appId = [ABDManager shareInstance].appId;
    if (appId == nil || appId.length == 0) {
        ABDLogWarning(@"appId 为空");
        return;
    }

    NSString *deviceId = [ABDManager shareInstance].deviceId;
    if (deviceId == nil || deviceId.length == 0) {
        ABDLogWarning(@"deviceId 为空");
        return;
    }
    if ([ABDNetManager isExpiredInfo:dateStr]) {
        ABDLogWarning(@"上传日期已经过期");
        return;
    }
    if (orderId.length > 0) {
        [ABDNetManager uploadLogsAppId:appId deviceId:deviceId orderId:orderId dateStr:dateStr forceUpload:forceUpload source:source extraInfo:extraInfo];
    }else{
        [self netWorkCheck:^(NSInteger statusCode) {
            if (callBack) {
                callBack(statusCode);
            }
            [ABDNetManager uploadLogsAppId:appId deviceId:deviceId orderId:orderId dateStr:dateStr forceUpload:forceUpload source:source extraInfo:extraInfo];
        }];
    }
}

// 开启网络检测
+ (void)netWorkCheck:(ABDUploadResult)callBack
{
    // 判断与上次网络检测间隔是否超过5分钟
    double timeInterval = [[[NSUserDefaults standardUserDefaults] valueForKey:@"ABDNetCheckTimeInterval"] doubleValue];
    NSInteger timeDuring = ([NSDate date].timeIntervalSince1970 * 1000 - timeInterval) / 1000;
    if (timeDuring <= 300) {
        callBack(1000);
        return;
    }
    // 启动网络检测
    ABDNetCheckService * service =  [[ABDNetCheckService alloc]init];
    [service checkNetStatus:^(BOOL isSuccess, NSString * _Nullable result) {
        
        [self writeLog:result type:ABDTypeNetworkLog];
        if (isSuccess) {
            NSTimeInterval  timeInterval =  ([NSDate date].timeIntervalSince1970) * 1000;
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:timeInterval] forKey:@"ABDNetCheckTimeInterval"];
            callBack(1000);
        }else{
            callBack(-1001);
        }
    }];
}

#pragma mark-- 日志失败重试
// 检查本地上传失败的日志信息
+ (void)reuploadFailLogData
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([ABDManager shareInstance].appId.length > 0) {
            [ABDNetManager checkLocalFailTask];
        }
    });
}

#pragma mark -ABD 日志相关的信息
+ (NSDictionary *)allLogFileInfo
{
    return ABDCoreAllFilesInfo();
}

+ (NSString *)getCurrentTime
{
    return ABDCoreTodaysDate();
}

+ (NSDictionary *)getAllLogFileInfo
{
    return ABDCoreAllFilesInfo();
}

+ (NSString *)getCurrentDeviceId
{
    return [ABDManager shareInstance].deviceId;
}

+ (NSString *)getCurrentAppId
{
    return [ABDManager shareInstance].appId;
}


@end
