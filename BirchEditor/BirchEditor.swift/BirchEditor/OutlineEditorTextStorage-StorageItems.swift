//
//  OutlineEditorTextStorage-StorageItems.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/12/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Foundation

extension OutlineEditorTextStorage {
    public func itemAtIndex(_ location: Int) -> ItemType? {
        return storageItemAtIndex(location)?.item
    }

    public func itemForID(_ id: String) -> ItemType {
        return storageItemForID(id).item
    }

    public func storageItemAtIndex(_ location: Int, effectiveRange: NSRangePointer? = nil) -> OutlineEditorTextStorageItem? {
        if let id = attributes(at: location, effectiveRange: effectiveRange ?? nil)[.storageItemIDAttributeName] as? String {
            return storageItemForID(id)
        }
        return nil
    }

    public func storageItemsInRange(_ range: NSRange) -> [OutlineEditorTextStorageItem] {
        let itemIDs = itemIDsInRange(range)
        var items: [OutlineEditorTextStorageItem] = []
        cacheStorageItemsForIDs(itemIDs)
        for each in itemIDs {
            items.append(idsToStorageItems[each]!)
        }
        return items
    }

    public func storageItemForID(_ id: String) -> OutlineEditorTextStorageItem {
        if let item = idsToStorageItems[id] {
            return item
        }
        cacheStorageItemsForIDs([id])
        return idsToStorageItems[id]!
    }

    func itemIDsInRange(_ range: NSRange) -> [String] {
        return outlineEditor!.jsOutlineEditor.invokeMethod("getItemIDsInRange", withArguments: [range.location, range.length]).toArray() as! [String]
    }

    func invalidateRange(_ range: NSRange) {
        if range.length > 0 {
            clearComputedAttributesInRange(paragraphRange(for: range))
        }
    }

    func invalidateItemsInRange(_ range: NSRange) {
        enumerateParagraphRanges(in: paragraphRange(for: range)) { enclosingRange, _ in
            if let id = self.backingStorage.attribute(.storageItemIDAttributeName, at: enclosingRange.location, effectiveRange: nil) as? String {
                self.idsToStorageItems.removeValue(forKey: id)
            }
        }
    }

    fileprivate func cacheStorageItemsForIDs(_ ids: [String]) {
        var idsToLoad: [String] = []
        for each in ids {
            if idsToStorageItems[each] == nil {
                idsToLoad.append(each)
            }
        }

        let computedStyleMetadata = outlineEditor!.jsOutlineEditor.invokeMethod("getComputedStyleMetadataForItemIDs", withArguments: [idsToLoad]).toArray()
        var i = 0
        while i < (computedStyleMetadata?.count)! {
            let id = computedStyleMetadata?[i] as! String
            let type = computedStyleMetadata?[i + 1] as! String
            let indentLevel = computedStyleMetadata?[i + 2] as! CGFloat
            let itemStyleKeyPath = computedStyleMetadata?[i + 3] as! String
            let runStylesCount = computedStyleMetadata?[i + 4] as! Int
            i += 5

            let runStylesEnd = i + (runStylesCount * 3)
            var runStyles: [OutlineEditorTextStorageItem.RunStyle] = []
            while i < runStylesEnd {
                let runStyleKeyPath = computedStyleMetadata?[i] as! String
                var runLink = computedStyleMetadata?[i + 1] as? String
                let runLength = computedStyleMetadata?[i + 2] as! Int
                i += 3

                if runLink?.utf16.count == 0 {
                    runLink = nil
                }

                runStyles.append(OutlineEditorTextStorageItem.RunStyle(styleKeyPath: runStyleKeyPath, link: runLink, length: runLength))
            }

            idsToStorageItems[id] = OutlineEditorTextStorageItem(
                id: id,
                type: type,
                indentLevel: indentLevel,
                styleKeyPath: itemStyleKeyPath,
                runStyles: runStyles,
                outlineEditor: outlineEditor!
            )
        }
    }
}
