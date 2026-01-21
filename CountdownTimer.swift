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
    }
    public typealias CountdownCallback = (_ count: Int, _ finished: Bool) -> Void
    private var countdowns = [String: Countdown]()
    private var scenarioCallbacks = [String: CountdownCallback]()
    private var subscribedScenarioKeys = [String: String]()
    static private let shared = CountdownTimer()
    private let lock = NSLock()
    private let timerQueue = DispatchQueue(label: "com.remember17.countdowntimer", qos: .utility)

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
        let timer = DispatchSource.makeTimerSource(flags: [], queue: timerQueue)
        timer.schedule(wallDeadline: .now(), repeating: 1, leeway: .milliseconds(100))
        timer.setEventHandler(handler: { [weak self] in
            let currentTimeInterval = Date().timeIntervalSince1970
            let remaining = endTimeInterval - currentTimeInterval
            let result = max(Int(ceil(remaining)), 0)
            DispatchQueue.main.async {
                self?.handleCallback(key, result, result == 0)
            }
        })
        return timer
    }

    private func handleCallback(_ key: Countdownable, _ count: Int, _ finished: Bool) {
        guard let (callback, scenarioCallbacksSnapshot) = getCallbacksSnapshot(for: key) else {
            remove(key: key)
            return
        }
        callback(count, finished)
        for scenarioCallback in scenarioCallbacksSnapshot {
            scenarioCallback(count, finished)
        }
        guard finished else { return }
        remove(key: key)
    }
}

extension CountdownTimer {
    private func addCountdown(key: Countdownable,
                              countdown: Countdown) {
        lock.lock()
        if let existing = countdowns[key.countdownKey] {
            existing.timer?.cancel()
        }
        countdowns[key.countdownKey] = countdown
        lock.unlock()
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

    private func getCallbacksSnapshot(for key: Countdownable) -> (CountdownCallback, [CountdownCallback])? {
        lock.lock()
        guard let countdown = countdowns[key.countdownKey],
              let callback = countdown.callBack else {
            lock.unlock()
            return nil
        }
        let scenarioCallbacksSnapshot = subscribedScenarioKeys.compactMap { scenario, countdownKey -> CountdownCallback? in
            guard countdownKey == key.countdownKey else { return nil }
            return scenarioCallbacks[scenario]
        }
        lock.unlock()
        return (callback, scenarioCallbacksSnapshot)
    }
    
    private func remove(key: Countdownable) {
        lock.lock()
        if let countdown = countdowns.removeValue(forKey: key.countdownKey) {
            countdown.timer?.cancel()
        }
        lock.unlock()
    }

    private func resume(key: Countdownable) {
        lock.lock()
        countdowns[key.countdownKey]?.timer?.resume()
        lock.unlock()
    }
}
