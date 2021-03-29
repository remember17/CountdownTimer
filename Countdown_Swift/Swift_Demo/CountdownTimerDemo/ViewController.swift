//
//  ViewController.swift
//  CountdownTimerDemo
//
//  Created by 吴浩 on 2019/10/27.
//  Copyright © 2019 wuhao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var countdownLabel1: UILabel!
    @IBOutlet private weak var countdownLabel2: UILabel!
 
    // ⚠️ 注意使用weak self
    @IBAction private func didClickStartTimer1Button(_ sender: Any) {
        CountdownTimer.startTimer(key: .test1, count: 60) { [weak self] (count, finish) in
            self?.countdownLabel1.text = finish ? "Finished" : "\(count)"
        }
    }
    
    @IBAction private func didClickStartTimer2Button(_ sender: Any) {
        CountdownTimer.startTimer(key: .test2, count: 10) { [weak self] (count, finish) in
            self?.countdownLabel2.text = finish ? "Finished" : "\(count)"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        CountdownTimer.stopTimer(key: .test1)
    }
}

