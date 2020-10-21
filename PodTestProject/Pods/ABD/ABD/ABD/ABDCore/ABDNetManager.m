//
//  ABDNetManager.m
//  ABD-iOS
//
//  Created by 刘贺松 on 2019/3/29.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import "ABDNetManager.h"
#import "ABDCore.h"
#import "ABDUtils.h"
#import "ABDLog.h"
#import "ABDReachability.h"
#import "ABDNetworkRequest.h"

#define ABD_SLICE_LENGTH (1 * 1024 * 1024)
#define ABD_REUPLOAD_TIMEINTERVAL 1 * 24 * 60 * 60

@interface ABDNetManager ()
@property (nonatomic, assign) NSInteger localKey;
@property (nonatomic, copy) NSString *ABDBaseUrl;
@property (nonatomic, strong) NSMutableDictionary *uploadDictQueue;
@end

@implementation ABDNetManager

+ (instancetype)shareInstance
{
    static ABDNetManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ABDNetManager alloc] init];
    });
    return instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ABDBaseUrl    = @"https://bfiles.pingan.com.cn/brop/stp/cust/mobile_monitor/abd/abd-log/report";
        self.localKey = 0;
    }
    return self;
}

+ (void)setUploadUrl:(NSString *)uploadUrl
{
    if (uploadUrl.length > 0) {
        [ABDNetManager shareInstance].ABDBaseUrl = uploadUrl;
    }
}

//本地记录上传请求信息，同时发起请求
+ (void)uploadLogsAppId:(NSString *)appId deviceId:(NSString *)deviceId orderId:(NSString *)orderId dateStr:(NSString *)dateStr forceUpload:(BOOL)forceUpload source:(nonnull NSString *)source extraInfo:(nonnull NSString *)extraInfo
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:appId forKey:@"X-appId"];
    [dict setValue:deviceId forKey:@"X-deviceId"];
    [dict setValue:dateStr forKey:@"X-logTime"];
    [dict setValue:orderId forKey:@"X-orderId"];
    [dict setValue:source forKey:@"X-source"];
    [dict setValue:[self localInfo] forKey:@"X-localInfo"];
    [dict setValue:[self appVersion] forKey:@"X-appVersion"];
    
    [dict setValue:[self netType] forKey:@"X-network"];

    [dict setValue:@"iOS" forKey:@"X-platform"];
    [dict setValue:ABD_Encrypt_Verison forKey:@"X-abdSecV"];
    [dict setValue:ADB_SDK_Version forKey:@"X-sdkVersion"];
    [dict setValue:extraInfo forKey:@"X-att"];
    [dict setValue:@(forceUpload) forKey:@"forceUpload"];
    NSTimeInterval  writeInterval = [[NSDate date] timeIntervalSince1970];
    [dict setValue:[NSNumber numberWithFloat:writeInterval] forKey:@"writeInterval"];
    [dict setValue:@(NO) forKey:@"uploadSuccess"];
    [self writeUploadInfo:dateStr params:[dict copy]];
    
    NSDictionary * dateDict = [[self uploadLogsInfo] valueForKey:dateStr];
    
    NSInteger taskId = 0;
    for (NSString * obj in [dateDict allKeys]) {
        if (taskId < [obj integerValue]) {
            taskId = [obj integerValue];
        }
    }
    
    [self sendUploadAction:dateStr taskId:[NSString stringWithFormat:@"%ld",taskId]];
}

#pragma mark 发起网络网络请求
+ (void)sendUploadAction:(NSString *)dateStr taskId:(NSString *)taskId
{
    NSArray * array = [[ABDNetManager shareInstance].uploadDictQueue valueForKey:dateStr];
    if (array.count > 0) {
        NSMutableArray * arr = [NSMutableArray arrayWithArray:array];
        [arr addObject:taskId];
        [[ABDNetManager shareInstance].uploadDictQueue setValue:arr forKey:dateStr];
    }else{
        NSMutableArray * arr = [NSMutableArray array];
        [arr addObject:taskId];
        [[ABDNetManager shareInstance].uploadDictQueue setValue:arr forKey:dateStr];
        [self uploadAction:dateStr taskId:taskId];
    }
}
// 发起上报
+ (void)uploadAction:(NSString *)dateStr taskId:(NSString *)taskId
{
    NSDictionary * dateDic = [[self uploadLogsInfo] valueForKey:dateStr];
    NSDictionary * taskDic = [dateDic valueForKey:taskId];
    NSString * orderId = [taskDic valueForKey:@"X-orderId"];
    if (orderId.length > 0) { // 区分 push 指令回传还是主动上报
        [self sendPusAction:dateStr taskId:taskId taskParams:taskDic];
    } else {
        [self sendUploadDateStr:dateStr taskId:taskId parmas:taskDic uploadData:YES];
    }
}

// push 指令上报
+ (void)sendPusAction:(NSString *)dateStr taskId:(NSString *)taskId taskParams:(NSDictionary *)taskParam
{
    NSString * logId = @"";
    
    NSDictionary *dateDic = [[self uploadLogsInfo] valueForKey:dateStr];
    if ([dateDic isKindOfClass:[NSDictionary class]]) {
        for (NSDictionary *obj in [dateDic allValues]) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                logId = [obj valueForKey:@"X-logId"];
                if (logId.length > 0) {
                    break;
                }
            }
        }
    }
    
    bool forceUpload = [[taskParam valueForKey:@"forceUpload"] boolValue];
    
    if (logId && logId.length > 0) {
        if (forceUpload) {
            [self sendUploadDateStr:dateStr taskId:taskId parmas:[taskParam copy] uploadData:YES];
        } else {
            [self sendUploadDateStr:dateStr taskId:taskId parmas:[taskParam copy] uploadData:NO];
        }
    } else {
        [self sendUploadDateStr:dateStr taskId:taskId parmas:[taskParam copy] uploadData:YES];
    }
}

// 判断是否需要上报日志数据
+ (void)sendUploadDateStr:(NSString *)dateStr taskId:(NSString *)taskId parmas:(NSDictionary *)params uploadData:(BOOL)uploadData
{
    if (uploadData) {
        ABDCoreUploadFilePath(dateStr, ^(NSString *_Nullable filePath) {
            NSString *dataMD5         = [ABDUtils encode_md5_data:[NSData dataWithContentsOfFile:filePath]];
            NSData *data              = [NSData dataWithContentsOfFile:filePath];
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:params];
            [dict setValue:dataMD5 forKey:@"X-md5"];
            [self sendAction:dateStr taskId:taskId params:dict data:data];
        });

    } else {
        [self sendAction:dateStr taskId:taskId params:params data:nil];
    }
}

// 发起网络上传的请求
+ (void)sendAction:(NSString *)dateStr taskId:(NSString *)taskId params:(NSDictionary *)params data:(NSData *)logData
{
    BOOL isUploadSuccess = [[params valueForKey:@"uploadSuccess"] boolValue];
    if (isUploadSuccess) {
        [self checkUnUploadAction:dateStr];
        return;
    }
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:params];
    NSString * logTime = [[dict valueForKey:@"X-logTime"] componentsSeparatedByString:@"_"].firstObject;
    [dict setValue:logTime forKey:@"X-logTime"];
    [dict removeObjectForKey:@"writeInterval"];
    [dict removeObjectForKey:@"retryTime"];
    [dict removeObjectForKey:@"forceUpload"];
    [dict removeObjectForKey:@"uploadSuccess"];
    
    NSString *urlStr = [ABDNetManager shareInstance].ABDBaseUrl;

    [[ABDNetworkRequest shareInstance] uploadTaskWithUrl:urlStr
                                                  params:[dict copy]
                                                    data:logData
                                            withComplete:^(NSError *_Nullable err, ABDResponseObject *_Nullable responseObject) {
                                                if (responseObject.success) {
                                                    [self updateSuccessLogInfo:dateStr logId:responseObject.logId taskId:taskId];
                                                } else {
                                                    [self reUploadDateStr:dateStr taskId:taskId data:logData];
                                                }
                                            }];
}


#pragma mark 重新上传失败的日志信息
// 失败重传机制
+ (void)reUploadDateStr:(NSString *)dateStr taskId:(NSString *)taskId data:(NSData *)logData
{
    NSMutableDictionary *dic      = [NSMutableDictionary dictionaryWithDictionary:[self uploadLogsInfo]];
    NSMutableDictionary *dateInfo = [NSMutableDictionary dictionaryWithDictionary:[dic valueForKey:dateStr]];
    NSMutableDictionary * taskDict = [dateInfo valueForKey:taskId];
    NSInteger retryTime           = [[taskDict valueForKey:@"retryTime"] integerValue];
    if (retryTime <= 0) {
        [self checkUnUploadAction:dateStr];
        return;
    }
    retryTime = retryTime - 1;
    // 随机数进行延迟，防止后端并发的问题
    NSUInteger  randomTime =  arc4random_uniform(10) + (6 - retryTime) * 30;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(randomTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendAction:dateStr taskId:taskId params:taskDict data:logData];
    });

    [taskDict setValue:@(retryTime) forKey:@"retryTime"];
    [dateInfo setValue:taskDict forKey:taskId];
    [dic setValue:dateInfo forKey:dateStr];
    [dic writeToFile:[self plistPath] atomically:YES];
}

#pragma-- mark 检查本地是否存在待上传的任务信息
// 更新本地的上传日志信息
+ (void)updateSuccessLogInfo:(NSString *)dateStr logId:(NSString *)logId taskId:(NSString *)taskId
{
    NSMutableDictionary *dic      = [NSMutableDictionary dictionaryWithDictionary:[self uploadLogsInfo]];
    NSMutableDictionary *dataInfo = [NSMutableDictionary dictionaryWithDictionary:[dic valueForKey:dateStr]];
    
    NSMutableDictionary *taskDict = [NSMutableDictionary dictionaryWithDictionary:[dataInfo valueForKey:dateStr]];
    [taskDict setValue:@(YES) forKey:@"uploadSuccess"];
    [dataInfo setValue:taskDict forKey:taskId];

    for (NSString * keyStr in dataInfo.allKeys) {
        NSMutableDictionary * mutableTemDict = [NSMutableDictionary dictionaryWithDictionary:[dataInfo valueForKey:keyStr]];
        [mutableTemDict setValue:logId forKey:@"X-logId"];
        [dataInfo setValue:mutableTemDict forKey:keyStr];
    }
    [dic setValue:dataInfo forKey:dateStr];
    [dic writeToFile:[self plistPath] atomically:YES];
    
    [self checkUnUploadAction:dateStr];
}
+ (void)checkUnUploadAction:(NSString *)dateStr
{
    NSMutableArray * arr = [[ABDNetManager shareInstance].uploadDictQueue valueForKey:dateStr];
    if (arr.count <= 0) {
        return;
    }
    [arr removeObjectAtIndex:0];
    if (arr.count > 0) {
        NSString * taskId = arr.firstObject;
        [self uploadAction:dateStr taskId:taskId];
    }
}

#pragma mark 写入本地日志信息
// 写上传日志信息到本地
+ (void)writeUploadInfo:(NSString *)dateStr params:(NSDictionary *)params
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[self uploadLogsInfo]];
    if (dic == nil) {
        dic = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *dateDict = [NSMutableDictionary dictionaryWithDictionary:[dic valueForKey:dateStr]];
    if (dateDict == nil) {
        dateDict = [[NSMutableDictionary alloc] init];
    }
    
    if ([ABDNetManager shareInstance].localKey == 0) {

        NSInteger tempKey = 0;
        for (NSString * obj in [dateDict allKeys]) {
            if (tempKey < [obj integerValue]) {
                tempKey = [obj integerValue];
            }
        }
        [ABDNetManager shareInstance].localKey = tempKey + 1;
    }
    NSMutableDictionary *dataInfoDict = [NSMutableDictionary dictionaryWithDictionary:params];
    [dataInfoDict setValue:@(5) forKey:@"retryTime"];
    
    [dateDict setValue:[dataInfoDict copy] forKey:[NSString stringWithFormat:@"%ld",(long)[ABDNetManager shareInstance].localKey]];
    [dic setValue:[dateDict copy] forKey:dateStr];
    [dic writeToFile:[self plistPath] atomically:YES];
    [ABDNetManager shareInstance].localKey += 1;
}

//// 更新本地数据信息
//+ (void)updateLocalInfo:(NSString *)dateStr key:(NSString *)keyStr value:(id)valueObj
//{
//    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[self uploadLogsInfo]];
//    if (dic == nil) {
//        return;
//    }
//    NSMutableDictionary *dateDict = [dic valueForKey:dateStr];
//    if (dateDict == nil) {
//        return;
//    }
//    [dateDict setValue:valueObj forKey:keyStr];
//    [dic setValue:dateDict forKey:dateStr];
//    [dic writeToFile:[self plistPath] atomically:YES];
//}

// 移除掉对应的日志信息
+ (void)removeLocalInfo:(NSString *)dateStr key:(NSString *)keyStr
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[self uploadLogsInfo]];
    if (dic == nil) {
        return;
    }
    NSMutableDictionary *dateDict = [dic valueForKey:dateStr];
    if (dateDict == nil) {
        return;
    }
    [dateDict removeObjectForKey:keyStr];
    [dic setValue:dateDict forKey:dateStr];
    [dic writeToFile:[self plistPath] atomically:YES];
}

#pragma mark  检查本地失败的上传任务
+(void)checkLocalFailTask
{
    NSDictionary *dict = [self uploadLogsInfo];
    for (NSString *dateStr in dict) {
        if ([self isExpiredInfo:dateStr]) {
            [self removeDateInfo:dateStr];
        } else {
            [self checkDateTaskExpiredInfo:dateStr];
        }
    }
}
+ (void)checkDateTaskExpiredInfo:(NSString *)dateStr
{
    NSDictionary * dict = [[self uploadLogsInfo] valueForKey:dateStr];
    for (NSString * taskId in dict.allKeys) {
        NSTimeInterval  temp = [[[dict valueForKey:taskId] valueForKey:@"writeInterval"] doubleValue];
        NSTimeInterval currentTimeInterval = [NSDate new].timeIntervalSince1970;
        BOOL isUploadSuccess = [[[dict valueForKey:taskId] valueForKey:@"uploadSuccess"] boolValue];
        if ((currentTimeInterval - temp > ABD_REUPLOAD_TIMEINTERVAL) && isUploadSuccess == NO) {
            [self removeLocalInfo:dateStr key:taskId];
        }else if(isUploadSuccess == NO){
            [self sendUploadAction:dateStr taskId:taskId];
        }
    }   
}

#pragma  mark   工具方法
// 检验信息是否过期
+ (BOOL)isExpiredInfo:(NSString *)dateStr
{
    NSTimeInterval currentTimeInterval = [NSDate new].timeIntervalSince1970;
    NSDateFormatter *dateFormatter     = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSString *fileS = [dateStr componentsSeparatedByString:@"_"].firstObject;
    NSDate *data    = [dateFormatter dateFromString:fileS];
    if ((currentTimeInterval - data.timeIntervalSince1970) * 1000 > ABD_Expired_Time) {
        return YES;
    }
    return NO;
}

+ (void)removeDateInfo:(NSString *)dateInfo
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[self uploadLogsInfo]];
    [dic removeObjectForKey:dateInfo];
    [dic writeToFile:[self plistPath] atomically:YES];
}

+ (NSDictionary *)uploadLogsInfo
{
    return [[NSDictionary alloc] initWithContentsOfFile:[self plistPath]];
}

+ (NSString *)plistPath
{
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"ABDCoreLoggerv3/ABDCache.plist"];
}
-(NSMutableDictionary *)uploadDictQueue{
    if (_uploadDictQueue == nil) {
        _uploadDictQueue = [[NSMutableDictionary alloc]init];
    }
    return _uploadDictQueue;
}

#pragma mark - 日志的基本信息
// 日志文件的MD5值
- (NSString *)fileMD5:(NSString *)filePath
{
    NSString *dataMD5Str = [ABDUtils encode_md5_data:[NSData dataWithContentsOfFile:filePath]];
    return dataMD5Str;
}

// 本地的日志列表信息
+ (NSString *)localInfo
{
    NSDictionary *dict    = ABDCoreAllFilesInfo();
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSString *key in dict.allKeys) {
        NSString *dataInfo = [NSString stringWithFormat:@"%@_%@", key, [dict valueForKey:key]];
        [array addObject:dataInfo];
    }
    NSString * jsonStr = [ABDUtils ObjectToJSONString:[array copy]];
    return jsonStr;
}

//网络状态4G或者WiFi
+ (NSString *)netType
{
    NSString *netType = @"";
    if ([ABDReachability sharedManager].reachableViaWiFi) {
        netType = @"Wifi";
    }else if([ABDReachability sharedManager].reachableViaWWAN){
        netType = @"Cellular";
    }
    return netType;
}

//APP的版本号
+(NSString *)appVersion
{
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return appVersion;
}
@end
