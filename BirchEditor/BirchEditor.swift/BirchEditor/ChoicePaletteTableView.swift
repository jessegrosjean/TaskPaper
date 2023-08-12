import Cocoa

class ChoicePaletteTableView: NSTableView {
    
    override var canBecomeKeyView: Bool {
        return false
    }

    override var acceptsFirstResponder: Bool {
        return false
    }
    
}
