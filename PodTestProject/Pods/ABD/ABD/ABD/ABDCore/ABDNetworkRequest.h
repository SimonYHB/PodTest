//
//  ABDNetworkRequest.h.h
//  ABD-iOS
//
//  Created by 刘贺松 on 2019/3/14.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ABDResponseObject;

typedef void (^ABDNetworkComplection)(NSError * _Nullable err, ABDResponseObject * _Nullable responseObject);
NS_ASSUME_NONNULL_BEGIN

@interface ABDResponseObject : NSObject

@property (nonatomic, copy) NSString *logId;
@property (nonatomic, assign) BOOL success;
@end

@interface ABDNetworkRequest : NSObject

+ (instancetype)shareInstance;

/**
 上传日志信息

 @param urlStr 传递的URL地址信息
 @param params 对应的参数信息
 @param data 对应的日志信息
 @param networkComplection 对应的返回信息
 @return 返回的task
 */
- (NSURLSessionDataTask *)uploadTaskWithUrl:(NSString *)urlStr params:(NSDictionary *)params data:(NSData *)data withComplete:(ABDNetworkComplection)networkComplection;

@end

NS_ASSUME_NONNULL_END
