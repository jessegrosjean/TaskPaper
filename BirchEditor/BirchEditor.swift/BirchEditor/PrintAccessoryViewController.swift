//
//  PrintAccessoryViewController.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/6/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

extension NSPrintInfo.AttributeKey {
    static let headerAndFooter = NSPrintInfo.AttributeKey(rawValue: "PrintHeaderAndFooterDefaultsKey")
    static let backgroundColor = NSPrintInfo.AttributeKey(rawValue: "PrintBackgroundColorDefaultsKey")
    static let styleSheetURL = NSPrintInfo.AttributeKey(rawValue: "PrintStyleSheetURLDefaultsKey")
}

class PrintAccessoryViewController: NSViewController, NSPrintPanelAccessorizing {
    @IBOutlet var printStyleSheetPopUpButton: NSPopUpButton!
    @IBOutlet var printHeaderAndFooterCheckbox: NSButton!
    @IBOutlet var printBackgroundColorCheckbox: NSButton!

    override func viewDidLoad() {
        menuNeedsUpdate(printStyleSheetPopUpButton.menu!)
        printStyleSheetPopUpButton.selectItem(at: printStyleSheetPopUpButton.indexOfItem(withRepresentedObject: printStyleSheetURL))
    }

    override var representedObject: Any? {
        didSet {
            printHeaderAndFooter = userDefaults.bool(forKey: NSPrintInfo.AttributeKey.headerAndFooter.rawValue)
            printBackgroundColor = userDefaults.bool(forKey: NSPrintInfo.AttributeKey.backgroundColor.rawValue)
            printStyleSheetURL = userDefaults.url(forKey: NSPrintInfo.AttributeKey.styleSheetURL.rawValue) ?? StyleSheet.defaultStyleSheetURL
        }
    }

    @objc dynamic var printHeaderAndFooter: Bool {
        get {
            return printingValue(.headerAndFooter) as? Bool ?? false
        }
        set(flag) {
            printHeaderAndFooterCheckbox.state = flag ? .on : .off
            userDefaults.set(flag, forKey: NSPrintInfo.AttributeKey.headerAndFooter.rawValue)
            setPrintingValue(flag, key: .headerAndFooter)
        }
    }

    @objc dynamic var printBackgroundColor: Bool {
        get {
            return printingValue(.backgroundColor) as? Bool ?? false
        }
        set(flag) {
            printBackgroundColorCheckbox.state = flag ? .on : .off
            userDefaults.set(flag, forKey: NSPrintInfo.AttributeKey.backgroundColor.rawValue)
            setPrintingValue(flag, key: .backgroundColor)
        }
    }

    @objc dynamic var printStyleSheetURL: URL {
        get {
            return printingValue(.styleSheetURL) as? URL ?? StyleSheet.defaultStyleSheetURL as URL
        }
        set(url) {
            userDefaults.set(url, forKey: NSPrintInfo.AttributeKey.styleSheetURL.rawValue)
            setPrintingValue(url, key: .styleSheetURL)
        }
    }

    @IBAction func togglePrintHeaderAndFooter(_: Any?) {
        printHeaderAndFooter = !printHeaderAndFooter
    }

    @IBAction func togglePrintBackgroundColor(_: Any?) {
        printBackgroundColor = !printBackgroundColor
    }

    @IBAction func updatePrintStyleSheet(_ sender: Any?) {
        if let styleSheetURL = (sender as? NSMenuItem)?.representedObject as? URL {
            printStyleSheetURL = styleSheetURL
        }
    }

    func printingValue(_ key: NSPrintInfo.AttributeKey) -> Any? {
        return (representedObject as? NSPrintInfo)?.dictionary().object(forKey: key)
    }

    func setPrintingValue(_ value: Any?, key: NSPrintInfo.AttributeKey) {
        if let value = value {
            (representedObject as? NSPrintInfo)?.dictionary().setObject(value, forKey: key as NSCopying)
        } else {
            (representedObject as? NSPrintInfo)?.dictionary().removeObject(forKey: key)
        }
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(updatePrintStyleSheet(_:)) {
            if printStyleSheetURL == (menuItem.representedObject as? URL) {
                menuItem.state = .on
            } else {
                menuItem.state = .off
            }
        }
        return true
    }

    func keyPathsForValuesAffectingPreview() -> Set<String> {
        return Set(["printHeaderAndFooter", "printBackgroundColor", "printStyleSheetURL"])
    }

    func localizedSummaryItems() -> [[NSPrintPanel.AccessorySummaryKey: String]] {
        return [[
            .itemName: NSLocalizedString("Header and Footer", tableName: "PrintAccessoryView", comment: "itemName"),
            .itemDescription: printHeaderAndFooter ? "On" : "Off",
        ]]
    }
}

extension PrintAccessoryViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let styleSheetURLs = StyleSheet.styleSheetsURLs
        if styleSheetURLs.count > 0 {
            for each in styleSheetURLs {
                let path = each.path
                let item = NSMenuItem(title: path.lastPathComponent, action: #selector(updatePrintStyleSheet(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = each
                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(withTitle: NSLocalizedString("Open StyleSheet Folder", tableName: "PrintAccessoryView", comment: "menu"), action: #selector(OutlineEditorAppDelegate.openStyleSheetsFolder(_:)), keyEquivalent: "")
    }
}

extension OutlineEditorView {
    override func beginDocument() {
        super.beginDocument()

        if let viewController = delegate as? OutlineEditorViewController, let printDictionary = NSPrintOperation.current?.printInfo.dictionary() {
            if let styleSheetURL = printDictionary[NSPrintInfo.AttributeKey.styleSheetURL.rawValue] as? URL {
                viewController.styleSheet = StyleSheet(source: styleSheetURL, scriptContext: BirchOutline.sharedContext)
            } else {
                viewController.styleSheet = nil
            }
            if let printBackgroundColor = printDictionary[NSPrintInfo.AttributeKey.backgroundColor.rawValue] as? Bool, !printBackgroundColor {
                backgroundColor = NSColor.clear
            }
        }

        if let textStorage = textStorage {
            layoutManager?.ensureLayout(forCharacterRange: NSMakeRange(0, textStorage.length))
        }
    }
}
