//
//  NSView-RootView.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/7/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

extension NSView {
    var rootView: NSView {
        var each = self
        while let superview = each.superview {
            each = superview
        }
        return each
    }

    var ancestorViews: [NSView] {
        var ancestors = [NSView]()
        var each = self
        while let superview = each.superview {
            ancestors.append(superview)
            each = superview
        }
        return ancestors
    }

    var ancestorViewsWithSelf: [NSView] {
        var ancestors = ancestorViews
        ancestors.insert(self, at: 0)
        return ancestors
    }
}
