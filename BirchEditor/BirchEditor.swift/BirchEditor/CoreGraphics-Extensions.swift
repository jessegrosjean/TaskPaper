//
//  CoreGraphics-Extensions.swift
//  TextInputClientText
//
//  Created by Jesse Grosjean on 2/10/17.
//  Copyright © 2017 Jesse Grosjean. All rights reserved.
//

import Foundation

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return CGFloat(hypotf(Float(x - point.x), Float(y - point.y)))
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
