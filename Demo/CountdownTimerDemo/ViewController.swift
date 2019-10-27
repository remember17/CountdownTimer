//
//  ViewController.swift
//  CountdownTimerDemo
//
//  Created by wuhao on 2019/10/27.
//  Copyright © 2019 wuhao. All rights reserved.
//

import UIKit

enum Countdowns: String, Countdownable {
    case test1, test2

    var countdownKey: String {
        return rawValue
    }
}

class ViewController: UIViewController {

    @IBOutlet private weak var countdownLabel1: UILabel!
    @IBOutlet private weak var countdownLabel2: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        CountdownTimer.subscribe(key: Countdowns.test1, for: "scenario1") { count, finished in
            print("🐯==> \(count) : \(finished)")
        }
    }

    @IBAction private func didClickStartTimer1Button(_ sender: Any) {
        CountdownTimer.start(key: Countdowns.test1, count: 60) { [weak self] (count, finished) in
            self?.countdownLabel1.text = "\(count)"
        }
    }
    
    @IBAction private func didClickStartTimer2Button(_ sender: Any) {
        CountdownTimer.start(key: Countdowns.test2, count: 30) { [weak self] (count, finished) in
            self?.countdownLabel2.text = "\(count)"
        }
        CountdownTimer.subscribe(key: Countdowns.test1, for: "scenario2") { count, finished in
            print("🐯--> \(count) : \(finished)")
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        CountdownTimer.cancel(key: Countdowns.test2)
        CountdownTimer.unsubscribe(scenario: "scenario2")
    }
}
