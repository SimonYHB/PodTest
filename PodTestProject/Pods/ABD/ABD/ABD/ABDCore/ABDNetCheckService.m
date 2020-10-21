//
//  ABDNetCheckSevice.m
//  ABD
//
//  Created by 刘贺松 on 2019/10/30.
//  Copyright © 2019 pingan. All rights reserved.
//

#import "ABDNetCheckService.h"
#include <netdb.h>
#include <arpa/inet.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "ABDReachability.h"
#import "ABDNetPing.h"
#import "ABDUtils.h"
typedef void (^ABDCDNCheckResult)(BOOL isSuccess, NSString * _Nullable result);

@interface ABDNetCheckService()<ABDNetPingDelegate>
{
    struct sockaddr_in remote_addr;
    NSMutableString *_logInfo;  //记录网络诊断log日志
    ABDNetPing *_netPinger;
}

@property (nonatomic, copy) ABDNetCheckCallBack result;
@property (nonatomic, assign) NSInteger pingCount;

@end
@implementation ABDNetCheckService
-(instancetype)init{
    self = [super init];
    if (self) {
        _logInfo = [[NSMutableString alloc]initWithCapacity:20];
        _pingCount = 2;
    }
    return self;
}

- (void)checkNetStatus:(ABDNetCheckCallBack)result
{
    self.result = result;
    // 1、判断网络状态
    [self recordStepInfo:@"开始判断网络状....\n"];
    if ([ABDReachability sharedManager].networkReachabilityStatus == ABDReachabilityStatusReachableViaWiFi ) {
        [self recordStepInfo:@"网络环境：WiFi"];
    }
    switch ([ABDReachability sharedManager].networkReachabilityStatus) {
        case ABDReachabilityStatusReachableViaWiFi:
            [self recordStepInfo:@"网络环境：WiFi \n"];
            break;
        case ABDReachabilityStatusReachableViaWWAN:
            [self recordStepInfo:@"网络环境：4G \n"];
            break;
        case ABDReachabilityStatusNotReachable:
            [self recordStepInfo:@"网络环境：NotReachable \n"];
            break;
        case ABDReachabilityStatusUnknown:
            [self recordStepInfo:@"网络环境：Unknown \n"];
            break;
            
        default:
            break;
    }
    [self getCarrierInfo];
    
    //2、Check CDN Status
    [self recordStepInfo:@"开始 CDN 状态检测....\n"];
    //DNS 解析 b.pingan.com.cn
    [self checkCDNStatus:^(BOOL isSuccess, NSString * _Nullable resultStr) {
        [self recordStepInfo:resultStr];
        if (isSuccess == NO) {
            result(NO,resultStr);
            return ;
        }
        [self recordStepInfo:@"开始 DNS 解析....\n"];
        
        [self recordStepInfo:@"域名:b.pingan.com.cn"];
        NSArray * array =  [self getDNSsWithDormain:@"b.pingan.com.cn"];
        [self recordStepInfo:[ABDUtils ObjectToJSONString:array]];
        [self startPingAction];
    }];
}

-(void)startPingAction
{
    //诊断ping信息, 同步过程
    NSMutableArray *pingAdd = [[NSMutableArray alloc] init];
    NSMutableArray *pingInfo = [[NSMutableArray alloc] init];
    [pingAdd addObject:@"www.baidu.com"];
    [pingInfo addObject:@"baidu"];
    [pingAdd addObject:@"www.taobao.com"];
    [pingInfo addObject:@"taobao"];
    
    [self recordStepInfo:@"\n开始ping..."];
    _netPinger = [[ABDNetPing alloc] init];
    _netPinger.delegate = self;
    for (int i = 0; i < [pingAdd count]; i++) {
        [self recordStepInfo:[NSString stringWithFormat:@"ping: %@ %@ ...",
                              [pingInfo objectAtIndex:i],
                              [pingAdd objectAtIndex:i]]];
       [_netPinger runWithHostName:[pingAdd objectAtIndex:i]];
    }
}
-(void)appendPingLog:(NSString *)pingLog
{
    [self recordStepInfo:pingLog];
}
- (void)pingFinishEnd
{
    self.pingCount -= 1;
    if (self.pingCount <1) {
        self.result(YES, _logInfo);
    }
}

// CDN 检测
- (void)checkCDNStatus:(ABDCDNCheckResult)result
{
    __block NSURLSessionDataTask *dataTask = nil;
    NSString * urlStr = @"http://cdn.sdb.com.cn/m/dns_detect.png";
    
    NSURL *url                   = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15];
    
    [request setHTTPMethod:@"GET"];
    
    dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSMutableString * resultStr = [[NSMutableString alloc]initWithCapacity:20];
        if (response) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            [resultStr appendString:[httpResponse.URL absoluteString]];
            [resultStr appendString:[NSString stringWithFormat:@"%ld\n",(long)httpResponse.statusCode]];
            [resultStr appendString:[ABDUtils ObjectToJSONString:[httpResponse allHeaderFields]]];
                result(YES,resultStr);
        }else{
            [resultStr appendString:[NSString stringWithFormat:@"%ld\n",(long)error.code]];
            [resultStr appendString:[error domain]];
            result(NO,resultStr);
        }
    }];
    [dataTask resume];
}

// 记录信息
- (void)recordStepInfo:(NSString *)stepInfo
{
    if (!stepInfo) {
        stepInfo = @"";
    }
    [_logInfo appendString:stepInfo];
    [_logInfo appendString:@"\n"];
}

#pragma mark -- DNS解析地址
//通过hostname获取ip列表 DNS解析地址
- (NSArray *)getDNSsWithDormain:(NSString *)hostName
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *IPV4DNSs = [self getIPV4DNSWithHostName:hostName];
    if (IPV4DNSs && IPV4DNSs.count > 0) {
        [result addObjectsFromArray:IPV4DNSs];
    }
    
    //由于在IPV6环境下不能用IPV4的地址进行连接监测
    //所以只返回IPV6的服务器DNS地址
    NSArray *IPV6DNSs = [self getIPV6DNSWithHostName:hostName];
    if (IPV6DNSs && IPV6DNSs.count > 0) {
        [result removeAllObjects];
        [result addObjectsFromArray:IPV6DNSs];
    }
    return [NSArray arrayWithArray:result];
}

- (NSArray *)getIPV4DNSWithHostName:(NSString *)hostName
{
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    @try {
        phot = gethostbyname(hostN);
    } @catch (NSException *exception) {
        return nil;
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in_addr ip_addr;
        memcpy(&ip_addr, phot->h_addr_list[j], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        
        NSString *strIPAddress = [NSString stringWithUTF8String:ip];
        [result addObject:strIPAddress];
        j++;
    }
    return [NSArray arrayWithArray:result];
}

- (NSArray *)getIPV6DNSWithHostName:(NSString *)hostName
{
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    
    @try {
        /**
         * 只有在IPV6的网络下才会有返回值
         */
        phot = gethostbyname2(hostN, AF_INET6);
    } @catch (NSException *exception) {
        return nil;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in6_addr ip6_addr;
        memcpy(&ip6_addr, phot->h_addr_list[j], sizeof(struct in6_addr));
        NSString *strIPAddress = [self formatIPV6Address: ip6_addr];
        [result addObject:strIPAddress];
        j++;
    }
    
    return [NSArray arrayWithArray:result];
}

- (NSString *)formatIPV6Address:(struct in6_addr)ipv6Addr
{
    NSString *address = nil;
    
    char dstStr[INET6_ADDRSTRLEN];
    char srcStr[INET6_ADDRSTRLEN];
    memcpy(srcStr, &ipv6Addr, sizeof(struct in6_addr));
    if(inet_ntop(AF_INET6, srcStr, dstStr, INET6_ADDRSTRLEN) != NULL){
        address = [NSString stringWithUTF8String:dstStr];
    }
    
    return address;
}

// 获取运营商的信息
-(void)getCarrierInfo
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = nil;
    if (@available(iOS 12.1, *)) {
        //iOS12.0.x调用此方法会crash，iOS12.1.x apple修复了此问题
        if (netInfo && [netInfo respondsToSelector:@selector(serviceSubscriberCellularProviders)]) {
            NSDictionary *dic = [netInfo serviceSubscriberCellularProviders];
            if (dic.allKeys.count) {
                carrier = [dic objectForKey:dic.allKeys[0]];
            }
        }
    } else {
        carrier = [netInfo subscriberCellularProvider];
    }
    
    if (carrier != NULL) {
        NSString * carrierName = [carrier carrierName];
        [self appendPingLog:[NSString stringWithFormat:@"运营商：%@",carrierName]];
        NSString * ISOCountryCode = [carrier isoCountryCode];
        
        [self appendPingLog:[NSString stringWithFormat:@"isoCountryCode：%@",ISOCountryCode]];
        NSString *MobileCountryCode = [carrier mobileCountryCode];
        
        [self appendPingLog:[NSString stringWithFormat:@"mobileCountryCode：%@",MobileCountryCode]];
        NSString *  MobileNetCode = [carrier mobileNetworkCode];
        
        [self appendPingLog:[NSString stringWithFormat:@"mobileNetworkCode：%@\n",MobileNetCode]];
    }
}
@end

