//
//  NSMenu-Markdown.swift
//  Birch
//
//  Created by Jesse Grosjean on 9/27/16.
//
//

import Foundation

extension NSMenu {
    func toMarkdown() {
        var shortcuts = [String]()
        printMenu(menu: self, depth: 0, shortcuts: &shortcuts)

        print("| Shortcut | Description |")
        print("| --- | --- |")
        for each in shortcuts {
            print(each)
        }
    }
}

func printMenu(menu: NSMenu, depth: Int = 0, shortcuts: inout [String]) {
    for each in menu.items {
        if !each.isSeparatorItem {
            var keyShortcut = ""

            if let keyCode = each.keyEquivalent.utf16.first {
                if each.keyEquivalentModifierMask.contains(.control) {
                    keyShortcut.append(Character("⌃"))
                }

                if each.keyEquivalentModifierMask.contains(.option) {
                    keyShortcut.append(Character("⌥"))
                }

                if each.keyEquivalentModifierMask.contains(.shift) {
                    keyShortcut.append(Character("⇧"))
                }

                if each.keyEquivalentModifierMask.contains(.command) {
                    keyShortcut.append(Character("⌘"))
                }

                switch Int(keyCode) {
                case NSEvent.SpecialKey.upArrow.rawValue:
                    keyShortcut.append("↑")
                case NSEvent.SpecialKey.downArrow.rawValue:
                    keyShortcut.append("↓")
                case NSEvent.SpecialKey.leftArrow.rawValue:
                    keyShortcut.append("←")
                case NSEvent.SpecialKey.rightArrow.rawValue:
                    keyShortcut.append("→")
                case NSEvent.SpecialKey.deleteForward.rawValue:
                    keyShortcut.append("⌫")
                case NSEvent.SpecialKey.tab.rawValue:
                    keyShortcut.append("⇥")
                default:
                    switch each.keyEquivalent {
                    case "\u{1B}": // escape
                        keyShortcut.append("⎋")
                    case "\r": // return
                        keyShortcut.append("↩︎")
                    default:
                        keyShortcut.append(each.keyEquivalent.uppercased())
                    }
                }
            }

            if keyShortcut.utf16.count > 0 {
                // keyShortcut.replace("", template: "Command")
                shortcuts.append("| \(keyShortcut) | \(each.title) |")
                keyShortcut = " <kbd>\(keyShortcut)</kbd>"
            }

            let indent = String(repeating: "\t", count: depth)
            print("\(indent)* **\(each.title)\(keyShortcut)** – ")
            if let submenu = each.submenu {
                printMenu(menu: submenu, depth: depth + 1, shortcuts: &shortcuts)
            }
        }
    }
}

/*
 ##### TaskPaper

 * **About TaskPaper**
 * **Check For Update…** Check for new versions of TaskPaper (only in direct download version)
 * **Please Rate TaskPaper…** Rate TaskPaper in Mac App Store (only in Mac App Store version)
 * **Show License…** Show license information.
 * **Preferences… <kbd>⌘,</kbd>**
 * **Hide TaskPaper <kbd>⌘H</kbd>**
 * **Hide Others <kbd>⌥⌘H</kbd>**
 * **Show All**
 * **Quit TaskPaper <kbd>⌘Q</kbd>**

 ##### File

 * **New <kbd>⌘N</kbd>**
 * **New Tab <kbd>⌥⌘N</kbd>** Create new Tab on current document
 * **New Window <kbd>⌘N</kbd>** Create new Window on current document
 * **Open… <kbd>⌘O</kbd>**
 * **Close <kbd>⌘W</kbd>**
 * **Close All <kbd>⌥⌘W</kbd>**
 * **Save… <kbd>⌘S</kbd>**
 * **Save As… <kbd>⌥⇧⌘S</kbd>**
 * **Duplicate <kbd>⌘S</kbd>**
 * **Rename…**
 * **Move To…**
 * **Revert to Saved**
 * **Revert To**
 * **Page Setup…**
 * **Print…**

 ##### Edit

 * **Undo <kbd>⌘Z</kbd>**
 * **Redo <kbd>⌘Z</kbd>**
 * **Cut <kbd>⌘X</kbd>** Cut selection to clipboard (including folded regions)
 * **Copy <kbd>⌘C</kbd>** Copy selection to clipboard (including folded regions)
 * **Copy Displayed <kbd>⌥⌘C</kbd>** Copy selection to clipboard (excluding folded regions)
 * **Paste <kbd>⌘V</kbd>**
 * **Delete**
 * **Selection**
 * **Select Word <kbd>⌃W</kbd>** Expand selection to word boundaries
 * **Select Sentence <kbd>⌃S</kbd>** Expand selection to sentance boundaries
 * **Select Paragraph <kbd>⌘L</kbd>** Expand selection to paragraph boundaries
 * **Select Branch <kbd>⌘B</kbd>** Expand selection to branch boundaries
 * **Expand Selection <kbd>⌥⌘↑</kbd>** Expand selection one level (i.e. from word to sentance boundaries)
 * **Contract Selection <kbd>⌥⌘↓</kbd>** Undo previous Expand Selection command
 * **Select All <kbd>⌘A</kbd>** Select all
 * **Find**
 * **Find… <kbd>⌘F</kbd>**
 * **Find and Replace… <kbd>⌥⌘F</kbd>**
 * **Find Next <kbd>⌘G</kbd>**
 * **Find Previous <kbd>⌘G</kbd>**
 * **Use Selection for Find <kbd>⌘E</kbd>**
     * **Jump to Selection <kbd>⌘J</kbd>**
 * **Spelling and Grammar**
 * **Show Spelling and Grammar <kbd>⌘:</kbd>**
 * **Check Document Now <kbd>⌘;</kbd>**
 * **Check Spelling While Typing**
 * **Check Grammar With Spelling**
 * **Correct Spelling Automatically**
 * **Substitutions**
 * **Show Substitutions**
 * **Smart Copy/Paste**
 * **Smart Quotes**
 * **Smart Dashes**
 * **Smart Links** (Ignored) TaskPaper always highlights links
 * **Data Detectors**
 * **Text Replacement**
 * **Transformations**
 * **Make Upper Case**
 * **Make Lower Case**
 * **Capitalize**
 * **Speech**
 * **Start Speaking**
 * **Stop Speaking**
 * **Start Dictation… <kbd>fn fn</kbd>**
 * **Emoji & Symbols <kbd>⌃⌘Space</kbd>**

 ##### Item

 * **New Task <kbd>⌘↩︎</kbd>** Insert a new Task
 * **New Note <kbd>⌃⌘↩︎</kbd>** Insert a new Note
 * **New Project <kbd>⌥⌘↩︎</kbd>** Insert a new Project
 * **Group <kbd>⌥⌘G</kbd>** Group selected items
 * **Duplicate <kbd>⌘D</kbd>** Duplicate selected items
 * **Format As**
 * **Projects** Reformat selected items as Projects
 * **Tasks** Reformat selected items as Tasks
 * **Notes** Reformat selected items as Notes
 * **Move Right <kbd>⌃⌘→</kbd>** Move selected items right
 * **Move Left <kbd>⌃⌘←</kbd>** Move selected items left
 * **Move Up <kbd>⌃⌘↑</kbd>** Move selected items up
 * **Move Down <kbd>⌃⌘↓</kbd>** Move selected items down
 * **Move to Project… <kbd>⌘\</kbd>** Move selected items to a Project in document
 * **Delete <kbd>⌃K</kbd>** Delete selected items

 ##### Tag

 * **Tag with... <kbd>⌘T</kbd>** Toggle choosen tag for selected items
     * **Tag with Done <kbd>⌘D</kbd>** Toggle @done for selected items
         * **Tag with Today <kbd>⌘Y</kbd>** Toggle @today for selected items
             * **Delete Tags in Selection <kbd>⌃⌥⌘K</kbd>** Remove all tags for selected items
                 * **Archive @done Items <kbd>⌘A</kbd>** Move all items tagged @done to "Archive:" project

 ##### Outline

 * **Go Home <kbd>⌘H</kbd>** Focus all the way out, showing all items
 * **Focus In <kbd>⌥⌘→</kbd>** Focus into a paricular item, showing only it and its descendants
 * **Focus Out <kbd>⌥⌘←</kbd>** Focus out a paricular item and its descendants
 * **Expand Items <kbd>⌘0</kbd>** Expand selected items
 * **Expand Items Completely <kbd>⌥⌘0</kbd>** Expand selected items and all descendants
 * **Collapse Items <kbd>⌘9</kbd>** Collapse selected items
 * **Collapse Items Completely <kbd>⌥⌘9</kbd>** Collapse selected items and all descendants
 * **Expand All By Level <kbd>⇧⌘0</kbd>** Expand all visible items by 1 level
 * **Expand All Completely <kbd>⌥⇧⌘0</kbd>** Expand all visible items
 * **Collapse All By Level <kbd>⇧⌘9</kbd>** Collapse all visible items by 1 level
 * **Collapse All Completely <kbd>⌥⇧⌘9</kbd>** Collapse all visible items

 ##### View

 * **Show Sidebar <kbd>⌥⌘S</kbd>** Show/Hide the sidebar
 * **New Sidebar Search** Create a new saved search in the sidebar
 * **Edit Sidebar Search** Edit the selected saved search in the sidebar
 * **Delete Sidebar Search** Delete the selected saved search from the sidebar
 * **Editor Searchbar <kbd>⌘F</kbd>** Show/Focus the editor's searchbar
 * **Refresh Editor Searchbar <kbd>⌘R</kbd>** Rerun the editor search
 * **Clear Editor Searchbar <kbd>⌘⎋</kbd>** Clear eidtor search
 * **Actual Size** Zoom editor to default size
 * **Zoom In <kbd>⌘+</kbd>** Zoom editor in
 * **Zoom Out <kbd>⌘-</kbd>** Zoom editor out

 ##### Palette

 * **Command <kbd>⌘P</kbd>** Show palette for commands
 * **Go to Anything <kbd>⌘P</kbd>** Show palette for projects, searches, tags
 * **Go to Project <kbd>⌥⌘P</kbd>** Show palette for projects
 * **Go to Search <kbd>⌃⌘P</kbd>** Show palette for search
 * **Go to Tag** Show palette for tags

 ##### Window

 * **StyleSheet**
 * **Open StyleSheet Folder** Open stylesheets folder in Finder
 * **Enter Full Screen <kbd>⌃⌘F</kbd>**
 * **Minimize <kbd>⌘M</kbd>**
 * **Zoom**
 * **Bring All to Front**

 ##### Help

 * **User's Guide <kbd>⌘?</kbd>**
 * **Email jesse@hogbaysoftware.com**
 * **Frequently Asked Questions**
 * **Support Forums**
 * **Release Notes**
 */
