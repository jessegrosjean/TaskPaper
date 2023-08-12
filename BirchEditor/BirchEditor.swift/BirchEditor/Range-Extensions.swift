//
//  NSRange-Extensions.swift
//  TextInputClientText
//
//  Created by Jesse Grosjean on 2/10/17.
//  Copyright © 2017 Jesse Grosjean. All rights reserved.
//

import Foundation

extension NSRange {
    var toCFRange: CFRange {
        return CFRange(location: location, length: length)
    }

    var max: Int {
        return location + length
    }

    func intersection(range: CFRange) -> NSRange? {
        return intersection(range: NSMakeRange(range.location, range.length))
    }

    func intersection(range: NSRange) -> NSRange? {
        var first = self
        var second = range

        if first.location > range.location {
            let tmp = first
            first = second
            second = tmp
        }

        if second.location < first.max {
            let end = min(first.max, second.max)
            return NSRange(location: second.location, length: end - second.location)
        }

        return nil
    }
}
