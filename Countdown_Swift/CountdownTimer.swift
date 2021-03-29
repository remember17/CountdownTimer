//
//  CountdownTimer.swift
//
//  Created by 吴浩 on 2019/10/27.
//  Copyright © 2019 wuhao. All rights reserved.
//  https://github.com/remember17/CountdownTimer

import UIKit

class CountdownTimer {
    
    // 当需要一个倒计时的时候就在这里加一个key
    enum CountDownKey: CaseIterable {
        case test1
        case test2
    }
    
    private struct CountDownInfo {
        var timer: DispatchSourceTimer?
        var endTime: TimeInterval?
        var callBack: CountDownCallback?
    }
    
    static private let shared = CountdownTimer()
    typealias CountDownCallback = (_ count: Int, _ finished: Bool) -> Void
    private var countDowns = [CountDownKey: CountDownInfo]()
    private let lock = NSLock()
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    /// 开启某个倒计时
    ///
    /// - Parameters:
    ///   - key: 倒计时key
    ///   - count: 倒计时长
    ///   - callBack: 回调
    static func startTimer(key: CountDownKey, count: Int, callBack: @escaping CountDownCallback) {
        // Calculate the end time
        let endTime = TimeInterval(count) + Date().timeIntervalSince1970
        CountdownTimer.shared.startCountDown(key: key, endTime: endTime, callBack: callBack)
    }
    
    /// 停止一个倒计时
    ///
    /// - Parameter key: 倒计时key
    static func stopTimer(key: CountDownKey) {
        CountdownTimer.shared.handleCallback(key, 0, true)
    }
    
    /// 继续某个倒计时
    ///
    /// - Parameters:
    ///   - key: 倒计时key
    ///   - callBack: 回调
    static func continueTimer(key: CountDownKey, callBack: @escaping CountDownCallback) {
        CountdownTimer.shared.continueCountDown(key: key, callBack: callBack)
    }
    
    /// 判断某个倒计时是否已经完成
    ///
    /// - Parameter key: 倒计时key
    /// - Returns: 倒计时是否完成
    static func isFinishedTimer(key: CountDownKey) -> Bool {
        return CountdownTimer.shared.isFinished(key: key)
    }
}

extension CountdownTimer {
    private func startCountDown(key: CountDownKey, endTime: TimeInterval, callBack: @escaping CountDownCallback) {
        let countDownInfo = CountDownInfo(timer: nil, endTime: endTime, callBack: callBack)
        addCountDown(key: key, countDownInfo: countDownInfo)
        launchTimer(key: key, countDownInfo: countDownInfo)
    }
    
    private func continueCountDown(key: CountDownKey, callBack: @escaping CountDownCallback) {
        lock.lock()
        let countEndTime = countDowns[key]?.endTime
        lock.unlock()
        guard let endTime = countEndTime, isExpired(endTime: endTime) == false else {
            // already finished
            handleCallback(key, 0, true)
            return
        }
        removeCountDown(key: key)
        startCountDown(key: key, endTime: endTime, callBack: callBack)
    }
    
    private func isFinished(key: CountDownKey) -> Bool {
        lock.lock()
        let finished = countDowns[key]?.timer?.isCancelled ?? true
        lock.unlock()
        return finished
    }
    
    @objc
    private func willEnterForegroundNotification() {
        for key in CountDownKey.allCases {
            guard let callBack = countDowns[key]?.callBack else {
                continue
            }
            continueCountDown(key: key, callBack: callBack)
        }
    }
}

extension CountdownTimer {
    private func launchTimer(key: CountDownKey, countDownInfo: CountDownInfo) {
        var info = countDownInfo
        let timer = createCountDownTimer(key: key)
        info.timer = timer
        addCountDown(key: key, countDownInfo: info)
        timer?.resume()
    }
    
    private func isExpired(endTime: TimeInterval) -> Bool {
        return Date().timeIntervalSince1970 >= endTime
    }
    
    private func addCountDown(key: CountDownKey, countDownInfo: CountDownInfo) {
        lock.lock()
        countDowns[key] = countDownInfo
        lock.unlock()
    }
    
    private func removeCountDown(key: CountDownKey) {
        lock.lock()
        countDowns[key]?.timer?.cancel()
        countDowns.removeValue(forKey: key)
        lock.unlock()
    }
    
    private func createCountDownTimer(key: CountDownKey) -> DispatchSourceTimer? {
        lock.lock()
        guard let endTime = countDowns[key]?.endTime else {
            return nil
        }
        lock.unlock()
        if isExpired(endTime: endTime) {
            handleCallback(key, 0, true)
            return nil
        }
        let countdownTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        countdownTimer.schedule(wallDeadline: .now(), repeating: 1)
        let currentTime = Date().timeIntervalSince1970
        var countDown = Int(round(endTime - currentTime)) + 1
        countdownTimer.setEventHandler(handler: {
            countDown -= 1
            let finished = countDown <= 0
            DispatchQueue.main.async {
                self.handleCallback(key, countDown, finished)
            }
        })
        return countdownTimer
    }
    
    private func handleCallback(_ key: CountDownKey, _ count: Int, _ finished: Bool) {
        guard let countCallBack = countDowns[key]?.callBack else {
            return
        }
        countCallBack(count, finished)
        if finished {
            removeCountDown(key: key)
        }
    }
}
