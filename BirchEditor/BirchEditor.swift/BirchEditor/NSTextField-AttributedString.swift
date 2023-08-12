//
//  NSTextField.swift
//  Birch
//
//  Created by Jesse Grosjean on 11/3/16.
//
//

import Cocoa

extension NSTextField {
    var attributedStringValueRemovingForegroundColor: NSMutableAttributedString {
        let attributedString = attributedStringValue.mutableCopy() as! NSMutableAttributedString
        attributedString.removeAttribute(NSAttributedString.Key.foregroundColor, range: NSMakeRange(0, attributedString.length))
        return attributedString
    }
}
