# CountdownTimer

A lightweight countdown manager: use a unique `countdownKey` to create and manage multiple countdowns; supports normal callbacks and scenario-based subscriptions.

## Use Cases
- Multiple countdowns in a list (flash sale, coupons, verification codes)
- Different modules need to subscribe to the same countdown

## Features
- Manage multiple countdowns at once
- Multiple scenario callbacks for the same countdown
- Callbacks are delivered on the main thread (safe for UI updates)

## Integration
Just add `CountdownTimer.swift` to your project.

## Quick Start

1) Define your key:

```swift
struct OrderCountdown: Countdownable {
    let countdownKey: String
}
```

2) Start a countdown:

```swift
let key = OrderCountdown(countdownKey: "order_123")
CountdownTimer.start(key: key, count: 10) { count, finished in
    print("Remaining: \(count) seconds")
    if finished {
        print("Finished")
    }
}
```

3) Cancel a countdown:

```swift
CountdownTimer.cancel(key: key)
```

## Scenario Subscriptions
Use this when multiple modules need updates from the same countdown:

```swift
CountdownTimer.subscribe(key: key, for: "list") { count, finished in
    print("List remaining: \(count)")
}

CountdownTimer.subscribe(key: key, for: "detail") { count, finished in
    print("Detail remaining: \(count)")
}

// Unsubscribe a scenario
CountdownTimer.unsubscribe(scenario: "list")
```

## API Overview
- `CountdownTimer.start(key:count:callBack:)`
- `CountdownTimer.cancel(key:)`
- `CountdownTimer.subscribe(key:for:callBack:)`
- `CountdownTimer.unsubscribe(scenario:)`

## Notes
- `countdownKey` must be unique, otherwise the countdown is restarted/overwritten.
- Callbacks are delivered on the main thread; update UI directly.

## License
MIT