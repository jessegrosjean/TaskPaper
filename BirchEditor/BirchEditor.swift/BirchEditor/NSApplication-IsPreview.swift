//
//  NSApplication-IsPreview.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/19/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

extension NSApplication {
    public var isPreview: Bool {
        let bundleInfo = Bundle.main.infoDictionary!
        let currentShortVersion = bundleInfo["CFBundleShortVersionString"] as! String
        return currentShortVersion.range(of: "Preview") != nil
    }
}
