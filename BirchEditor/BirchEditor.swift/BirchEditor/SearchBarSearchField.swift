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
}
