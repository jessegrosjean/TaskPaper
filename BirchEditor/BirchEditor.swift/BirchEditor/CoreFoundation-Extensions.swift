//
//  CoreFoundation-Extensions.swift
//  TextInputClientText
//
//  Created by Jesse Grosjean on 2/10/17.
//  Copyright © 2017 Jesse Grosjean. All rights reserved.
//

import Foundation

extension CFRange {
    var toNSRange: NSRange {
        return NSRange(location: location, length: length)
    }
}
