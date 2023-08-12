//
//  SearchBarSearchField.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/1/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

protocol FirstResponderDelegate {
    func controlDidBecomeFirstResponder(_ sender: NSControl)
    func controlDidResignFirstResponder(_ sender: NSControl)
}

class SearchBarSearchField: NSSearchField {
    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()
        if didBecomeFirstResponder {
            (delegate as? FirstResponderDelegate)?.controlDidBecomeFirstResponder(self)
        }
        return didBecomeFirstResponder
    }

    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()
        if didResignFirstResponder {
            (delegate as? FirstResponderDelegate)?.controlDidResignFirstResponder(self)
        }
        return didResignFirstResponder
    }

    override func rectForSearchButton(whenCentered _: Bool) -> NSRect {
        var r = super.rectForSearchButton(whenCentered: false)
        r.size.width = 0
        return r
    }

    override func rectForSearchText(whenCentered _: Bool) -> NSRect {
        return bounds
    }

    override func rectForCancelButton(whenCentered _: Bool) -> NSRect {
        var r = super.rectForCancelButton(whenCentered: false)
        r.origin.x += r.size.width
        r.size.width = 0
        return r
    }
}
