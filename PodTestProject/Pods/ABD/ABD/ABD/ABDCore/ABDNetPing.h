//
//  ABDNetPing.h
//  ABD
//
//  Created by 刘贺松 on 2019/10/30.
//  Copyright © 2019 pingan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ABDSimplePing.h"

/*
 * @protocal LDNetPingDelegate监测Ping命令的的输出到日志变量；
 *
 */
@protocol ABDNetPingDelegate <NSObject>
// ping的信息
- (void)appendPingLog:(NSString *)pingLog;
// ping 结束
- (void)pingFinishEnd;
@end


/*
 * @class LDNetPing ping监控
 * 主要是通过模拟shell命令ping的过程，监控目标主机是否连通
 * 连续执行五次，因为每次的速度不一致，可以观察其平均速度来判断网络情况
 */
@protocol ABDNetPingDelegate;
@interface ABDNetPing : NSObject <SimplePingDelegate> {
}

@property (nonatomic, weak, readwrite) id<ABDNetPingDelegate> delegate;

/**
 * 通过hostname 进行ping诊断
 */
- (void)runWithHostName:(NSString *)hostName;

/**
 * 停止当前ping动作
 */
- (void)stopPing;

@end

