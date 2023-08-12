//
//  ItemPasteboardProvider.swift
//  Birch
//
//  Created by Jesse Grosjean on 8/23/16.
//
//

import BirchOutline
import Cocoa

class ItemPasteboardProvider: NSObject, NSPasteboardItemDataProvider {
    let item: ItemType
    weak var outlineEditor: OutlineEditorType?

    init(item: ItemType, outlineEditor: OutlineEditorType) {
        self.item = item
        self.outlineEditor = outlineEditor
    }

    @objc func pasteboard(_: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        // Local variable inserted by Swift 4.2 migrator.
        let type = convertFromNSPasteboardPasteboardType(type)

        if let outlineEditor = outlineEditor {
            if let items = ItemPasteboardUtilities.readItemsSerializedItemReferences(item, editor: outlineEditor) {
                item.setString(outlineEditor.serializeItems(items, options: ["type": type as Any]), forType: convertToNSPasteboardPasteboardType(type))
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSPasteboardPasteboardType(_ input: NSPasteboard.PasteboardType) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSPasteboardPasteboardType(_ input: String) -> NSPasteboard.PasteboardType {
    return NSPasteboard.PasteboardType(rawValue: input)
}
