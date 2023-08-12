//
//  String.swift
//  BirchOutline
//
//  Created by Jesse Grosjean on 6/28/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

public extension String {
    
    func localized(_ comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }

}
