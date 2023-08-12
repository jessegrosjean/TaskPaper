//
//  Font.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#if os(iOS)
    import UIKit
    typealias Font = UIFont
#elseif os(OSX)
    import Cocoa
    typealias Font = NSFont
#endif

func defaultUserFont() -> Font {
    #if os(iOS)
        return Font.preferredFontForTextStyle(UIFontTextStyleBody)
    #elseif os(OSX)
        return Font.userFont(ofSize: 0)!
    #endif
}
