//
//  CountdownTimer.h
//
//  Created by wu, hao on 2019/10/28.
//  Copyright © 2019 wuhao. All rights reserved.
//  https://github.com/remember17/CountdownTimer

#import <Foundation/Foundation.h>

// 当需要一个倒计时的时候就在这里加一个key
typedef enum : NSUInteger {
    test1 = 0,
    test2,
} CountdownKey;

typedef void(^CountdownCallback)(NSInteger count, BOOL isFinished);

@interface CountdownTimer : NSObject

/**
 开启某个倒计时
 
 @param key 倒计时key
 @param count 倒计时长
 @param callback 回调
 */
+ (void)startTimerWithKey:(CountdownKey)key
                    count:(NSInteger)count
                 callBack:(CountdownCallback)callback;

/**
 停止一个倒计时
 
 @param key 倒计时key
 */
+ (void)stopTimerWithKey:(CountdownKey)key;

/**
 继续某个倒计时
 
 @param key 倒计时key
 @param callback 回调
 */
+ (void)continueTimerWithKey:(CountdownKey)key
                     callBack:(CountdownCallback)callback;

/**
 判断某个倒计时是否已经完成
 
 @param key 倒计时key
 @return 倒计时是否完成
 */
+ (BOOL)isFinishedTimerWithKey:(CountdownKey)key;

@end
