//
//  PaletteViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 10/28/16.
//
//

import Cocoa

class PaletteViewController: NSViewController {
    var completionHandler: ((Any?) -> Void)?

    func performAction(_ sender: Any?) {
        completionHandler?(sender)
        completionHandler = nil
    }
}
