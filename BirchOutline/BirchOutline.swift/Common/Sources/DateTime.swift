//
//  DateTime.swift
//  BirchOutline
//
//  Created by Jesse Grosjean on 10/18/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation
import JavaScriptCore

public protocol DateTimeType: AnyObject {
    
    static func parse(dateTime: String) -> Date?
    static func format(dateTime: Date, showMillisecondsIfNeeded: Bool, showSecondsIfNeeded: Bool) -> String
    
}

public class DateTime: DateTimeType {

    static let jsDateTimeClass = BirchOutline.sharedContext.jsDateTimeClass

    public class func parse(dateTime: String) -> Date? {
        return jsDateTimeClass.invokeMethod("parse", withArguments: [dateTime]).selfOrNil()?.toDate()
    }
    
    public class func format(dateTime: Date, showMillisecondsIfNeeded: Bool=true, showSecondsIfNeeded: Bool=true) -> String {
        return jsDateTimeClass.invokeMethod("format", withArguments: [dateTime, showMillisecondsIfNeeded, showSecondsIfNeeded]).toString()
    }
    
}
