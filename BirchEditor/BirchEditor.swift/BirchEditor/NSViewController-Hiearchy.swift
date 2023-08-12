//
//  NSViewController-DescendentViewControllers.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/4/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

extension NSViewController {
    var rootViewController: NSViewController {
        var each = self
        while let parentController = each.parent {
            each = parentController
        }
        return each
    }

    var ancestorViewControllers: [NSViewController] {
        var ancestors = [NSViewController]()
        var each = self
        while let parentController = each.parent {
            ancestors.append(parentController)
            each = parentController
        }
        return ancestors
    }

    var ancestorViewControllersWithSelf: [NSViewController] {
        var ancestors = ancestorViewControllers
        ancestors.insert(self, at: 0)
        return ancestors
    }

    var descendentViewControllers: [NSViewController] {
        var descendants = [NSViewController]()
        func visit(_ viewController: NSViewController) {
            for each in viewController.children {
                descendants.append(each)
                visit(each)
            }
        }
        visit(self)
        return descendants
    }

    var descendentViewControllersWithSelf: [NSViewController] {
        var descendants = descendentViewControllers
        descendants.insert(self, at: 0)
        return descendants
    }
}
