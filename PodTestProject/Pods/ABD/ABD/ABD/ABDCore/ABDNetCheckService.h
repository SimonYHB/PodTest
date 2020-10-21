//
//  ABDNetCheckSevice.h
//  ABD
//
//  Created by 刘贺松 on 2019/10/30.
//  Copyright © 2019 pingan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ABDNetCheckCallBack)(BOOL isSuccess, NSString * _Nullable resultStr);
NS_ASSUME_NONNULL_BEGIN

@interface ABDNetCheckService : NSObject

/**
 开启网络检测

 @param result 网络检测结果
 */
- (void)checkNetStatus:(ABDNetCheckCallBack)result;

@end


NS_ASSUME_NONNULL_END
