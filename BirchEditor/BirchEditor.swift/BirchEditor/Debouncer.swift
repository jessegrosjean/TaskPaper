//
//  Debouncer.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/5/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

class Debouncer: NSObject {
    weak var timer: Timer?

    let callback: () -> Void
    let delay: Double

    init(delay: Double, callback: @escaping (() -> Void)) {
        self.delay = delay
        self.callback = callback
    }

    func call() {
        cancel()
        timer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(Debouncer.fire), userInfo: nil, repeats: false)
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }

    @objc func fire() {
        callback()
    }
}
