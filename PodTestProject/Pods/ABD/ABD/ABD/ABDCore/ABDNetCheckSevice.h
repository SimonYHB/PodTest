//
//  ABDNetCheckSevice.h
//  ABD
//
//  Created by 刘贺松 on 2019/10/30.
//  Copyright © 2019 pingan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ABDNetCheckSevice : NSObject

@end


@interface DomainLookUpRes : NSObject
@property (nonatomic,copy) NSString * name;
@property (nonatomic,copy) NSString * ip;

+ (instancetype)instanceWithName:(NSString *)name address:(NSString *)address;
@end

NS_ASSUME_NONNULL_END
