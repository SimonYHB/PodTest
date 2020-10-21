//
//  ABDNetworkRequest.h.m
//  ABD-iOS
//
//  Created by 刘贺松 on 2019/3/14.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import "ABDNetworkRequest.h"
#import "ABDLog.h"
#define ABDNetworkRequestTimeOut 15.0f

//字符串是否为空
#define CANNA_IS_STRING_NIL(string) (string == nil || [string isKindOfClass:[NSString class]] == NO || string.length == 0)

@interface ABDNetworkRequest ()

@end

@implementation ABDNetworkRequest

+ (instancetype)shareInstance
{
    static ABDNetworkRequest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ABDNetworkRequest alloc] init];
    });
    return instance;
}

-(NSURLSessionDataTask *)uploadTaskWithUrl:(NSString *)urlStr params:(NSDictionary *)params data:(NSData *)data withComplete:(ABDNetworkComplection)networkComplection
{
    __block NSURLSessionDataTask *dataTask = nil;
    NSURLRequest * requst = [self requestUrlStr:urlStr params:params bodyData:data];
    
    dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:requst completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            NSDictionary * responseDict = [self objectFromJSONData:data];
            if (responseDict.allKeys.count > 0 && [[responseDict valueForKey:@"code"] integerValue] == 2001) {
                ABDResponseObject *response = [[ABDResponseObject alloc] init];

                    response.success = YES;
                    response.logId = [responseDict valueForKey:@"logId"];
                networkComplection(nil, response);
                ABDLogInfo(@"上传成功");
            } else {
                ABDLogWarning(@"上传失败 error:%@", error);
                NSError * error = [NSError errorWithDomain:@"业务失败" code:[[responseDict valueForKey:@"code"] integerValue] userInfo:nil];
                networkComplection(error, nil);
            }
        } else {
            networkComplection(error, nil);
            ABDLogWarning(@"上传失败 error:%@", error);
        }
    }];
    [dataTask resume];
    return dataTask;
}
//创建请求对象
- (NSURLRequest *)requestUrlStr:(NSString *)urlStr params:(NSDictionary *)params bodyData:(NSData *)bodyData
{
    NSURL *url                   = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:ABDNetworkRequestTimeOut];

    [request setHTTPMethod:@"POST"];
    
    for (NSString * keyStr in params.allKeys) {
        id value = [params valueForKey:keyStr];
        if ([value isKindOfClass:[NSString class]] == NO) {
            NSString * temp = [NSString stringWithFormat:@"%@",value];
            value = temp;
        }
        [request setValue:value forHTTPHeaderField:keyStr];
    }
    NSString *boundary = [NSUUID UUID].UUIDString;

    // 设置请求头
    NSString *headStr = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:headStr forHTTPHeaderField:@"Content-Type"];

    //拼接请求体数据(0-6步)
    NSMutableData *requestMutableData = [NSMutableData data];

    //1.\r\n--Boundary+72D4CD655314C423\r\n
    NSMutableString *myString = [NSMutableString stringWithFormat:@"\r\n--%@\r\n", boundary];

    //2. Content-Disposition: form-data; name="form-data"; filename="001.png"\r\n  //
    [myString appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\";filename=\"abd_123.log\"\r\n"]];

    //3. Content-Type:application/octet-stream
    [myString appendString:[NSString stringWithFormat:@"Content-Type:application/octet-stream;charset=UTF-8\r\n\r\n"]];

    //转换成为二进制数据
    [requestMutableData appendData:[myString dataUsingEncoding:NSUTF8StringEncoding]];

    // 拼接上传的数据
    [requestMutableData appendData:bodyData];

    //6. \r\n--Boundary+72D4CD655314C423--\r\n  // 分隔符后面以"--"结尾，表明结束
    [requestMutableData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    //设置请求体
    request.HTTPBody = requestMutableData;

    return request;
}

- (id)objectFromJSONData:(NSData *)data
{
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
}

//对字符串进行url编码
- (NSString *)urlEncodeString:(NSString *)string
{
    if (@available(iOS 9.0, *)) {
        //iOS8特殊字符串会导致crash
        NSMutableCharacterSet *allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [allowedCharacterSet removeCharactersInString:@"!*'();:@&=+$,/?%#[]"];
        return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    } else {
        NSString *result = (NSString *)
        CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (CFStringRef)string,
                                                                  NULL,
                                                                  CFSTR("!*'();:@&=+$,/\?%#[] "),
                                                                  kCFStringEncodingUTF8));
        return result;
    }
}

@end

@implementation ABDResponseObject

-(instancetype)init{
    
    self = [super init];
    if (self) {
        self.logId = @"";
        self.success = NO;
    }
    return self;
}

@end
