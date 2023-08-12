//
//  PreferencesWindowController.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/5/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa
import JavaScriptCore

let preferencesBundle = Bundle(for: ChoicePaletteWindowController.self)
let preferencesStoryboard = NSStoryboard(name: "Preferences", bundle: preferencesBundle)
let preferencesWindowController = preferencesStoryboard.instantiateController(withIdentifier: "Preferences Window Controller") as! PreferencesWindowController

let NSProhibitMultipleTextSelectionByMouse = "NSProhibitMultipleTextSelectionByMouse"
//let NSShowAppCentricOpenPanelInsteadOfUntitledFile = "NSShowAppCentricOpenPanelInsteadOfUntitledFile"
let BHideSearchbarWhenEmpty = "BHideSearchbarWhenEmpty"
let BIncludeDateWhenTaggingDone = "BIncludeDateWhenTaggingDone"
let BRemoveExtraTagsWhenArchivingDone = "BRemoveExtraTagsWhenArchivingDone"
let BIncludeProjectWhenArchivingDone = "BIncludeProjectWhenArchivingDone"
let BSidebarFontSizeFollowsSystemPreferences = "BSidebarFontSizeFollowsSystemPreferences"
let BMaintainWindowSizeWhenTogglingSidebar = "BMaintainWindowSizeWhenTogglingSidebar"
let BMaintainItemPathFilterWhenHoisting = "BMaintainItemPathFilterWhenHoisting"
let BMaintainHoistedItemWhenFiltering = "BMaintainHoistedItemWhenFiltering"
let BAutocompleteTagsAsYouType = "BAutocompleteTagsAsYouType"
let BAutoformatListsAsYouType = "BAutoformatListsAsYouType"
let BShowPoofAnimationOnDelete = "BShowPoofAnimationOnDelete"
let BAllowDeleteBackwardToUnindentItems = "BAllowDeleteBackwardToUnindentItems"
let BCheckSpellingAsYouType = "BCheckSpellingAsYouType"
let BCheckGrammarWithSpelling = "BCheckGrammarWithSpelling"
let BCorrectSpellingAutomatically = "BCorrectSpellingAutomatically"
let BRemindersAlwaysUseDefaultList = "BRemindersAlwaysUseDefaultList"
let BRemindersAllowsImportOfCompletedItems = "BRemindersAllowsImportOfCompletedItems"
let BRemindersSuppressImportRemindersAlert = "BRemindersSuppressImportRemindersAlert"
let BSmartCopyPaste = "BSmartCopyPaste"
let BSmartQuotes = "BSmartQuotes"
let BSmartDashes = "BSmartDashes"
let BDataDetectors = "BDataDetectors"
let BTextReplacement = "BTextReplacement"
let BShowWelcomeText = "BShowWelcomeText"
let BShowPreviewBadge = "ShowPreviewBadge"
let SUFeedURL = "SUFeedURL"

@objc public protocol PreferencesStoreType: JSExport {
    func getPreference(_ key: String) -> Any?
    func storePreference(_ key: String, _ value: JSValue?)
}

class PreferencesWindowController: NSWindowController {
    static let jsBirchPreferences = BirchOutline.sharedContext.jsBirchPreferences

    static func showPreferences() {
        preferencesWindowController.showWindow(nil)
    }

    static func setupPreferencesStore() {
        userDefaults.register(defaults: [
            BShowPreviewBadge: true,
            NSProhibitMultipleTextSelectionByMouse: true,
            //NSShowAppCentricOpenPanelInsteadOfUntitledFile: false, why is this the default
            SUFeedURL: "https://www.replaced_later_in_code.com",
            BIncludeDateWhenTaggingDone: false,
            BRemoveExtraTagsWhenArchivingDone: false,
            BIncludeProjectWhenArchivingDone: false,
            BSidebarFontSizeFollowsSystemPreferences: false,
            BUserFontSizeDefaultsKey: BUserFontDefaultSize,
            BMaintainWindowSizeWhenTogglingSidebar: false,
            BMaintainItemPathFilterWhenHoisting: false,
            BMaintainHoistedItemWhenFiltering: false,
            BHideSearchbarWhenEmpty: true,
            BAutocompleteTagsAsYouType: true,
            BAutoformatListsAsYouType: true,
            BShowPoofAnimationOnDelete: true,
            BAllowDeleteBackwardToUnindentItems: true,
            BCheckSpellingAsYouType: false,
            BCheckGrammarWithSpelling: false,
            BCorrectSpellingAutomatically: true,
            BRemindersAlwaysUseDefaultList: false,
            BRemindersAllowsImportOfCompletedItems: false,
            BSmartCopyPaste: true,
            BSmartQuotes: false,
            BSmartDashes: false,
            BDataDetectors: true,
            BTextReplacement: true,
            BShowWelcomeText: true,
        ])
        jsBirchPreferences.setValue(userDefaults, forProperty: "nativePreferences")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @IBAction func openScriptsFolder(_: Any?) {
        if let directoryURL = try? FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let openPanel = NSOpenPanel()
            let appName = ProcessInfo.processInfo.processName
            openPanel.directoryURL = directoryURL
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.prompt = NSLocalizedString("Select Script Folder", tableName: "ScriptFolderPanel", comment: "button")
            openPanel.message = NSLocalizedString("Please choose \"\(openPanel.prompt!)\" to give \(appName) permission to run enclosed scripts.", tableName: "ScriptFolderPanel", comment: "message")
            openPanel.begin(completionHandler: { result in
                if result == NSApplication.ModalResponse.OK {
                    NSWorkspace.shared.open(directoryURL)
                }
            })
        }
    }
}

extension UserDefaults: PreferencesStoreType {
    public func getPreference(_ key: String) -> Any? {
        return object(forKey: key)
    }

    public func storePreference(_ key: String, _ value: JSValue?) {
        set(value?.selfOrNil()?.toObject(), forKey: key)
    }
}
