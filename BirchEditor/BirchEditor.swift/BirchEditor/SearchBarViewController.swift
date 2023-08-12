//
//  SearchBarViewController.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/1/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline

extension NSView {
    var enclosingStackView: NSStackView? {
        var each: NSView? = self
        while let superview = each?.superview {
            if let superview = superview as? NSStackView {
                return superview
            }
            each = superview
        }
        return nil
    }
}

class SearchBarViewController: NSViewController, OutlineEditorHolderType, StylesheetHolder {

    @IBOutlet var titleBarConstraint: NSLayoutConstraint!
    @IBOutlet var topDividerLine: NSView!
    @IBOutlet var searchField: SearchBarSearchField!
    @IBOutlet var noMatchesLabel: NSTextField!

    var itemPathFilterSubscription: DisposableType?
    var processingAutocomplete = false
    var searchFieldEditorString = ""
    var searchFieldTextColor = NSColor.black
    var searchFieldSecondaryTextColor = NSColor.gray
    var searchFieldErrorTextColor = NSColor.red
    var searchPlaceholderString: NSAttributedString?
    var isTabbedWindowObserver: NSObjectProtocol?

    deinit {
        itemPathFilterSubscription?.dispose()
        if let isTabbedWindowObserver = isTabbedWindowObserver {
            NotificationCenter.default.removeObserver(isTabbedWindowObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchField.centersPlaceholder = false
        searchField.drawsBackground = true
        searchField.backgroundColor = .clear
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.needsUpdateConstraints = true
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        guard let window = self.view.window as? OutlineEditorWindow else {
            return
        }

        if let isTabbedWindowObserver = isTabbedWindowObserver {
            NotificationCenter.default.removeObserver(isTabbedWindowObserver)
        }
        
        isTabbedWindowObserver = NotificationCenter.default.addObserver(forName: .isTabbedWindowDidChange, object: window, queue: nil) { [weak self] _ in
            self?.view.needsUpdateConstraints = true
        }

        titleBarConstraint?.isActive = false

        if let topAnchor = (window.contentLayoutGuide as? NSLayoutGuide)?.topAnchor {
            if #available(OSX 11.0, *) {
                if window.isTabbedWindow {
                    titleBarConstraint = topDividerLine.topAnchor.constraint(equalTo: topAnchor, constant: -1)
                } else {
                    titleBarConstraint = topDividerLine.topAnchor.constraint(equalTo: topAnchor, constant: 0)
                }
            } else {
                titleBarConstraint = topDividerLine.topAnchor.constraint(equalTo: topAnchor, constant: -1)
            }
            
            titleBarConstraint?.isActive = true
        }
    }

    internal var outlineEditor: OutlineEditorType? {
        didSet {
            itemPathFilterSubscription?.dispose()
            itemPathFilterSubscription = outlineEditor?.onDidChangeItemPathFilter { [weak self] in
                self?.updateSearchFieldVisibility()
            }
            updateSearchFieldVisibility()
        }
    }

    internal var styleSheet: StyleSheet? {
        didSet {
            if let computedStyle = styleSheet?.computedStyleForElement("searchbar") {
                view.superview!.appearance = computedStyle.allValues[.appearance] as? NSAppearance

                if let textColor = computedStyle.attributedStringValues[.foregroundColor] as? NSColor {
                    searchFieldTextColor = textColor
                }

                if let secondaryTextColor = computedStyle.allValues[.secondaryTextColor] as? NSColor {
                    searchFieldSecondaryTextColor = secondaryTextColor
                }

                if let errorTextColor = computedStyle.allValues[.errorTextColor] as? NSColor {
                    searchFieldErrorTextColor = errorTextColor
                }

                if let backgroundColor = computedStyle.attributedStringValues[.backgroundColor] as? NSColor {
                    view.wantsLayer = true
                    view.layer?.backgroundColor = backgroundColor.cgColor
                } else {
                    view.layer?.backgroundColor = nil
                }

                searchPlaceholderString = NSAttributedString(string: searchField.placeholderString ?? "Search", attributes: [
                    .font: searchField.font ?? NSFont.systemFont(ofSize: 0),
                    .foregroundColor: computedStyle.allValues[.placeholderColor] as? NSColor ?? NSColor.gray,
                ])

                highlightSearchField()
            }
        }
    }

    func highlightSearchField(_ text: String? = nil, textStorage: NSTextStorage? = nil) {
        let attributedString = textStorage ?? NSMutableAttributedString(string: text ?? searchField.stringValue, attributes: [.font: searchField.font!])
        BirchEditor.syntaxHighlightItemPath(
            attributedString,
            textColor: searchFieldTextColor,
            secondaryTextColor: searchFieldSecondaryTextColor,
            errorTextColor: searchFieldErrorTextColor
        )
        searchField.attributedStringValue = attributedString
        searchField.placeholderAttributedString = searchPlaceholderString
    }

    func updateSearchFieldVisibility() {
        let newFilter = outlineEditor?.itemPathFilter ?? ""

        highlightSearchField(newFilter)

        if newFilter.utf16.count > 0 {
            view.superview?.isHidden = false
            noMatchesLabel.isHidden = outlineEditor?.firstDisplayedItem != nil
        } else {
            noMatchesLabel.isHidden = true
            searchField.stringValue = ""
            searchField.currentEditor()?.string = ""
            if searchField.currentEditor() == nil, userDefaults.bool(forKey: BHideSearchbarWhenEmpty) {
                view.superview?.isHidden = true
            }
        }
    }

    func updateJSSearch(_ search: String) {
        if let outlineEditor = outlineEditor {
            outlineEditor.editorState = (hoistedItem: outlineEditor.hoistedItem, focusedItem: outlineEditor.focusedItem, itemPathFilter: search)
        }
    }

    @IBAction func beginSearch(_: Any?) {
        view.superview?.isHidden = false
        if let searchField = searchField {
            searchField.window?.makeFirstResponder(searchField)
        }
    }

    @IBAction func closeSearch(_: Any?) {
        view.window?.makeFirstResponder(searchField.nextKeyView)
        updateJSSearch("")
        view.superview?.isHidden = true
    }

    @IBAction func searchFieldAction(_: Any?) {
        updateJSSearch(searchField.stringValue)
    }
}

extension SearchBarViewController: FirstResponderDelegate, NSSearchFieldDelegate {
    func controlDidBecomeFirstResponder(_ sender: NSControl) {
        if let currentEditor = sender.currentEditor() as? NSTextView, let currentEditorStorage = currentEditor.textStorage {
            highlightSearchField(textStorage: currentEditorStorage)
            currentEditor.insertionPointColor = searchFieldTextColor
        }
    }

    func controlDidResignFirstResponder(_ sender: NSControl) {
        if let currentEditor = sender.currentEditor() as? NSTextView, let currentEditorStorage = currentEditor.textStorage {
            highlightSearchField(textStorage: currentEditorStorage)
            currentEditor.insertionPointColor = searchFieldTextColor
        }
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        guard let fieldEditor = obj.userInfo!["NSFieldEditor"] as? NSTextView, let textStorage = fieldEditor.textStorage else {
            return
        }
        fieldEditor.wordRangeLeadExtensionCharacters = NSCharacterSet(charactersIn: "@") as CharacterSet
        highlightSearchField(textStorage: textStorage)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let fieldEditor = obj.userInfo!["NSFieldEditor"] as? NSTextView, let textStorage = fieldEditor.textStorage else {
            return
        }
        fieldEditor.wordRangeLeadExtensionCharacters = nil
        searchField.attributedStringValue = textStorage
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let fieldEditor = obj.userInfo!["NSFieldEditor"] as? NSTextView, let textStorage = fieldEditor.textStorage else {
            return
        }

        let newSearchFieldEditorString = textStorage.string

        if userDefaults.bool(forKey: BAutocompleteTagsAsYouType) {
            if !processingAutocomplete, newSearchFieldEditorString.utf16.count > searchFieldEditorString.utf16.count {
                let range = fieldEditor.rangeForUserCompletion
                if range.location != NSNotFound, textStorage.substring(with: range).hasPrefix("@") {
                    processingAutocomplete = true
                    fieldEditor.complete(nil)
                    processingAutocomplete = false
                }
            }
        }

        searchFieldEditorString = newSearchFieldEditorString

        highlightSearchField(nil, textStorage: textStorage)
    }

    func control(_: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem _: UnsafeMutablePointer<Int>) -> [String] {
        guard let textStorage = textView.textStorage, let outlineEditor = outlineEditor else {
            return words
        }

        let partialWord = textStorage.substring(with: charRange)
        if partialWord.hasPrefix("@") {
            return outlineEditor.outlineSidebar?.getAutocompleteTagsForPartialTag(partialWord) ?? words
        }

        return words
    }

    func control(_ control: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSWindow.selectPreviousKeyView(_:)) {
            control.window?.makeFirstResponder(control.previousValidKeyView)
            return true
        }

        if commandSelector == #selector(NSWindow.selectNextKeyView(_:)) {
            control.window?.makeFirstResponder(control.nextValidKeyView)
            return true
        }

        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            if control.stringValue.utf16.count == 0 {
                closeSearch(nil)
                return true
            }
        }

        return false
    }
}

/*
 // Helper function inserted by Swift 4.2 migrator.
 fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
 	return input.rawValue
 }

 // Helper function inserted by Swift 4.2 migrator.
 fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
 	guard let input = input else { return nil }
 	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
 }
 */
