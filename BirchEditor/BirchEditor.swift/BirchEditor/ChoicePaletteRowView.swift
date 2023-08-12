import Cocoa

let sharedTableRowView = NSTableRowView()

class ChoicePaletteRowView: NSTableRowView {
    
    override var isEmphasized: Bool {
        get {
            return isSelected
        }
        set(value) {}
    }

    override func drawSelection(in dirtyRect: NSRect) {
        NSColor(red: 94 / 255.0, green: 151 / 255.0, blue: 247 / 255.0, alpha: 1.0).set()
        dirtyRect.fill()
    }
    
}
