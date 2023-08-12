//
//  TaskPaperOutlineEditorViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 10/31/16.
//
//

extension OutlineEditorViewController {
    @IBAction func toggleDone(_: Any?) {
        outlineEditor?.performCommand("outline-editor:toggle-done", options: nil)
    }

    @IBAction func toggleToday(_: Any?) {
        outlineEditor?.performCommand("outline-editor:toggle-today", options: nil)
    }

    @IBAction func toggleStart(_: Any?) {
        outlineEditor?.performCommand("outline-editor:toggle-start", options: nil)
    }

    @IBAction func toggleDue(_: Any?) {
        outlineEditor?.performCommand("outline-editor:toggle-due", options: nil)
    }

    @IBAction func setItemType(_ sender: NSMenuItem?) {
        if let sender = sender {
            switch sender.tag {
            case 1:
                outlineEditor?.performCommand("outline-editor:format-project", options: nil)
            case 2:
                outlineEditor?.performCommand("outline-editor:format-task", options: nil)
            default:
                outlineEditor?.performCommand("outline-editor:format-note", options: nil)
            }
        }
    }

    @IBAction func moveToProject(_: Any?) {
        guard let outlineEditor = outlineEditor, let sidebar = outlineEditor.outlineSidebar else {
            return
        }

        var choices = [sidebar.homeItem.cloneBranch()]
        choices.append(sidebar.projectsGroup.cloneBranch())

        let outline = outlineEditor.outline
        let placeholder = NSLocalizedString("Move to Project", tableName: "ChoicePalette", comment: "placeholder")
        ChoicePaletteWindowController.showChoicePalette(view.window, placeholder: placeholder, allowsEmptySelection: true, items: flattenChoicePaletteItemBranches(choices), completionHandler: { string, choicePaletteItems in

            if let string = string, let choicePaletteItems = choicePaletteItems {
                if choicePaletteItems.isEmpty {
                    let hoistedItem = outlineEditor.hoistedItem
                    let newProject = outline.createItem(string)
                    newProject.setAttribute("data-type", value: "project")
                    outline.groupUndo {
                        hoistedItem.insertChildren([newProject], beforeSibling: hoistedItem.firstChild)
                        self.outlineEditor?.moveBranches(nil, parent: newProject, nextSibling: newProject.firstChild, options: nil)
                    }
                } else {
                    if let project = self.outlineEditor?.outline.itemForID(choicePaletteItems[0].representedObject as! String) {
                        self.outlineEditor?.moveBranches(nil, parent: project, nextSibling: project.firstChild, options: ["moveSelectionWithItems": false])
                    }
                }
            }
        })
    }

    @IBAction func exportToReminders(_: Any?) {
        outlineEditor?.performCommand("outline-editor:export-to-reminders", options: nil)
    }

    @IBAction func exportCopyToReminders(_: Any?) {
        outlineEditor?.performCommand("outline-editor:export-copy-to-reminders", options: nil)
    }
}
