//
//  CountdownTimer.swift
//
//  Created by wuhao on 2019/10/27.
//  Copyright © 2019 wuhao. All rights reserved.
//  https://github.com/remember17/CountdownTimer

import UIKit

public protocol Countdownable {
    var countdownKey: String { get }
}

public class CountdownTimer {
    private struct Countdown {
        var key: Countdownable
        var endTimeInterval: TimeInterval
        var timer: DispatchSourceTimer?
        var callBack: CountdownCallback?
        var currentCount = 0
    }
    public typealias CountdownCallback = (_ count: Int, _ finished: Bool) -> Void
    private var countdowns = [String: Countdown]()
    private var scenarioCallbacks = [String: CountdownCallback]()
    private var subscribedScenarioKeys = [String: String]()
    static private let shared = CountdownTimer()
    private let lock = NSLock()

    public static func start(key: Countdownable,
                             count: Int,
                             callBack: @escaping CountdownCallback) {
        let endTimeInterval = TimeInterval(count) + Date().timeIntervalSince1970
        let timer = CountdownTimer.shared.createTimer(key: key, endTimeInterval: endTimeInterval)
        CountdownTimer.shared.addCountdown(key: key, countdown: Countdown(key: key,
                                                                          endTimeInterval: endTimeInterval,
                                                                          timer: timer,
                                                                          callBack: callBack))
        CountdownTimer.shared.resume(key: key)
    }

    public static func cancel(key: Countdownable) {
        CountdownTimer.shared.remove(key: key)
    }

    public static func subscribe(key: Countdownable,
                                 for scenario: String,
                                 callBack: @escaping CountdownCallback) {
        CountdownTimer.shared.addScenarioCallback(key: key, for: scenario, callBack: callBack)
    }

    public static func unsubscribe(scenario: String) {
        CountdownTimer.shared.removeScenarioCallback(scenario: scenario)
    }
}

extension CountdownTimer {
    private func createTimer(key: Countdownable, endTimeInterval: TimeInterval) -> DispatchSourceTimer? {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        timer.schedule(wallDeadline: .now(), repeating: 1)
        timer.setEventHandler(handler: {
            let currentTimeInterval = Date().timeIntervalSince1970
            var countdown = Int(round(endTimeInterval - currentTimeInterval))
            countdown -= 1
            let result = max(countdown, 0)
            DispatchQueue.main.async {
                self.handleCallback(key, result, result == 0)
            }
        })
        return timer
    }

    private func handleCallback(_ key: Countdownable, _ count: Int, _ finished: Bool) {
        guard var countdown = getCountdown(key: key),
              let callback = countdown.callBack else {
                  remove(key: key)
                  return
              }
        countdown.currentCount = count
        callback(count, finished)
        for (scenario, countdownKey) in subscribedScenarioKeys {
            if countdownKey == key.countdownKey,
               let scenarioCallback = getSubscribedInfo(scenario: scenario).scenarioCallback {
                scenarioCallback(count, finished)
            }
        }
        guard finished else { return }
        remove(key: key)
    }
}

extension CountdownTimer {
    private func addCountdown(key: Countdownable,
                              countdown: Countdown) {
        lock.lock()
        countdowns[key.countdownKey] = countdown
        lock.unlock()
    }

    private func getCountdown(key: Countdownable) -> Countdown? {
        lock.lock()
        let countdown = countdowns[key.countdownKey]
        lock.unlock()
        return countdown
    }

    private func addScenarioCallback(key: Countdownable,
                                     for scenario: String,
                                     callBack: @escaping CountdownCallback) {
        lock.lock()
        scenarioCallbacks[scenario] = callBack
        subscribedScenarioKeys[scenario] = key.countdownKey
        lock.unlock()
    }

    private func removeScenarioCallback(scenario: String) {
        lock.lock()
        scenarioCallbacks.removeValue(forKey: scenario)
        subscribedScenarioKeys.removeValue(forKey: scenario)
        lock.unlock()
    }

    private func getSubscribedInfo(scenario: String) -> (countdownKey: String?,
                                                         scenarioCallback: CountdownCallback?) {
        lock.lock()
        let countdownKey = subscribedScenarioKeys[scenario]
        let callback = scenarioCallbacks[scenario]
        lock.unlock()
        return (countdownKey, callback)
    }
    
    private func remove(key: Countdownable) {
        lock.lock()
        countdowns[key.countdownKey]?.timer?.cancel()
        countdowns[key.countdownKey]?.timer = nil
        countdowns[key.countdownKey]?.callBack = nil
        countdowns.removeValue(forKey: key.countdownKey)
        lock.unlock()
    }

    private func resume(key: Countdownable) {
        lock.lock()
        countdowns[key.countdownKey]?.timer?.resume()
        lock.unlock()
    }
}
