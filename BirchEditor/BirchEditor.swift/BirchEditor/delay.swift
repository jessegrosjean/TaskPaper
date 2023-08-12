//
//  delay.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/7/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure
    )
}
