# CountdownTimer

```
// Custom timer key
enum Countdowns: String, Countdownable {
    case test1, test2

    var countdownKey: String {
        return rawValue
    }
}
```

```
// start a timer
CountdownTimer.start(key: Countdowns.test1, count: 60) { [weak self] (count, finished) in
    self?.countdownLabel1.text = "\(count)"
}
```

```
// subscribe a timer
CountdownTimer.subscribe(key: Countdowns.test1, for: "scenario1") { count, finished in
    print("==> \(count) : \(finished)")
}
```

```
// unsubscribe a timer
CountdownTimer.unsubscribe(scenario: "scenario1")
```

```
// cancel a timer
CountdownTimer.cancel(key: Countdowns.test2)
```
