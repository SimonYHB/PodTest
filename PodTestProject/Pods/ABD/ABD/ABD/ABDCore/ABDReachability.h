//
//  ABDReachability.h
//  ABDemo
//
//  Created by 刘贺松 on 2019/9/4.
//  Copyright © 2019 刘贺松. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>

typedef NS_ENUM(NSInteger, ABDReachabilityStatus) {
    ABDReachabilityStatusUnknown          = -1,
    ABDReachabilityStatusNotReachable     = 0,
    ABDReachabilityStatusReachableViaWWAN = 1,
    ABDReachabilityStatusReachableViaWiFi = 2,
};

NS_ASSUME_NONNULL_BEGIN

@interface ABDReachability : NSObject


/**
 当前的网络状态
 */
@property (readonly, nonatomic, assign) ABDReachabilityStatus networkReachabilityStatus;

/**
 网络是否通
 */
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/**
 是否通过蜂窝网络
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/**
 是否通过WiFil连通
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

/**
 初始化
 */
+ (instancetype)sharedManager;

/**返回实例
 */
+ (instancetype)manager;

/**
 Creates and returns a network reachability manager for the specified domain.
 
 @param domain The domain used to evaluate network reachability.
 
 @return An initialized network reachability manager, actively monitoring the specified domain.
 */
+ (instancetype)managerForDomain:(NSString *)domain;

/**
 Creates and returns a network reachability manager for the socket address.
 
 @param address The socket address (`sockaddr_in6`) used to evaluate network reachability.
 
 @return An initialized network reachability manager, actively monitoring the specified socket address.
 */
+ (instancetype)managerForAddress:(const void *)address;

/**
 Initializes an instance of a network reachability manager from the specified reachability object.
 
 @param reachability The reachability object to monitor.
 
 @return An initialized network reachability manager, actively monitoring the specified reachability.
 */
- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability NS_DESIGNATED_INITIALIZER;

/**
 *  Unavailable initializer
 */
+ (instancetype)new NS_UNAVAILABLE;

/**
 *  Unavailable initializer
 */
- (instancetype)init NS_UNAVAILABLE;

///--------------------------------------------------
/// @name Starting & Stopping Reachability Monitoring
///--------------------------------------------------

/**
 Starts monitoring for changes in network reachability status.
 */
- (void)startMonitoring;

/**
 Stops monitoring for changes in network reachability status.
 */
- (void)stopMonitoring;

///-------------------------------------------------
/// @name Getting Localized Reachability Description
///-------------------------------------------------

/**
 Returns a localized string representation of the current network reachability status.
 */
- (NSString *)localizedNetworkReachabilityStatusString;

///---------------------------------------------------
/// @name Setting Network Reachability Change Callback
///---------------------------------------------------

/**
 Sets a callback to be executed when the network availability of the `baseURL` host changes.
 
 @param block A block object to be executed when the network availability of the `baseURL` host changes.. This block has no return value and takes a single argument which represents the various reachability states from the device to the `baseURL`.
 */
- (void)setReachabilityStatusChangeBlock:(nullable void (^)(ABDReachabilityStatus status))block;

@end

///----------------
/// @name Constants
///----------------

/**
 ## Network Reachability
 
 The following constants are provided by `ABDReachabilityManager` as possible network reachability statuses.
 
 enum {
 ABDReachabilityStatusUnknown,
 ABDReachabilityStatusNotReachable,
 ABDReachabilityStatusReachableViaWWAN,
 ABDReachabilityStatusReachableViaWiFi,
 }
 
 `ABDReachabilityStatusUnknown`
 The `baseURL` host reachability is not known.
 
 `ABDReachabilityStatusNotReachable`
 The `baseURL` host cannot be reached.
 
 `ABDReachabilityStatusReachableViaWWAN`
 The `baseURL` host can be reached via a cellular connection, such as EDGE or GPRS.
 
 `ABDReachabilityStatusReachableViaWiFi`
 The `baseURL` host can be reached via a Wi-Fi connection.
 
 ### Keys for Notification UserInfo Dictionary
 
 Strings that are used as keys in a `userInfo` dictionary in a network reachability status change notification.
 
 `ABDNetworkingReachabilityNotificationStatusItem`
 A key in the userInfo dictionary in a `ABDNetworkingReachabilityDidChangeNotification` notification.
 The corresponding value is an `NSNumber` object representing the `ABDReachabilityStatus` value for the current reachability status.
 */

///--------------------
/// @name Notifications
///--------------------

/**
 Posted when network reachability changes.
 This notification assigns no notification object. The `userInfo` dictionary contains an `NSNumber` object under the `ABDNetworkingReachabilityNotificationStatusItem` key, representing the `ABDReachabilityStatus` value for the current network reachability.
 
 @warning In order for network reachability to be monitored, include the `SystemConfiguration` framework in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (`Prefix.pch`).
 */
FOUNDATION_EXPORT NSString * const ABDNetworkingReachabilityDidChangeNotification;
FOUNDATION_EXPORT NSString * const ABDNetworkingReachabilityNotificationStatusItem;

///--------------------
/// @name Functions
///--------------------

/**
 Returns a localized string representation of an `ABDReachabilityStatus` value.
 */
FOUNDATION_EXPORT NSString * ABDStringFromNetworkReachabilityStatus(ABDReachabilityStatus status);

NS_ASSUME_NONNULL_END
#endif


