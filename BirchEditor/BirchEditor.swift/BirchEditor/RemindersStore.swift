//
//  RemindersStore.swift
//  Birch
//
//  Created by Jesse Grosjean on 10/26/16.
//
//

import BirchOutline
import EventKit

class RemindersStoreAccessError: NSError {
    init() {
        let appName = ProcessInfo.processInfo.processName
        let description = NSLocalizedString("\(appName) does not have access to Reminders", tableName: "Reminders", comment: "message text")
        let recoverySuggestion = NSLocalizedString("You may grant access through System Preferences > Security & Privacy > Privacy > Reminders.", tableName: "Reminders", comment: "message text")
        super.init(domain: "RemindersStore", code: 0, userInfo: [
            NSLocalizedDescriptionKey: description,
            NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let defaultListText = NSLocalizedString(" (Default List)", tableName: "Reminders", comment: "append to default calendar title text")

class RemindersStore {
    static let eventStore = EKEventStore()

    static func requestAccess(to entityType: EKEntityType, completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        eventStore.requestAccess(to: entityType) { granted, error in
            if granted {
                completion(granted, error)
            } else {
                completion(granted, error ?? RemindersStoreAccessError())
            }
        }
    }

    static func fetchReminderCalendars(callback: @escaping ([EKCalendar]?, Error?) -> Void) {
        RemindersStore.requestAccess(to: .reminder) { granted, error in
            if granted {
                let calendars = self.eventStore.calendars(for: .reminder)
                DispatchQueue.main.async {
                    callback(calendars, error)
                }
            } else {
                DispatchQueue.main.async {
                    callback(nil, error)
                }
            }
        }
    }

    static func fetchReminders(useDefaultList: Bool = false, allowCompletedReminders: Bool = false, callback: @escaping ([EKReminder]?, Error?) -> Void) {
        RemindersStore.requestAccess(to: .reminder) { granted, error in
            if granted {
                let calendar = NSCalendar.current
                var calendars = [self.eventStore.defaultCalendarForNewReminders()]
                if !useDefaultList {
                    calendars = self.eventStore.calendars(for: .reminder)
                }

                let eventStore = self.eventStore
                let predicate = allowCompletedReminders ?
                    eventStore.predicateForReminders(in: calendars as? [EKCalendar]) :
                    eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars as? [EKCalendar])
                self.eventStore.fetchReminders(matching: predicate, completion: { fetchedReminders in
                    let sortedReminders = fetchedReminders?.sorted {
                        if $0.isCompleted != $1.isCompleted {
                            return $1.isCompleted
                        }

                        var dueComponents0 = $0.dueDateComponents
                        var dueComponents1 = $1.dueDateComponents

                        if dueComponents0?.calendar == nil {
                            dueComponents0?.calendar = calendar
                        }

                        if dueComponents1?.calendar == nil {
                            dueComponents1?.calendar = calendar
                        }

                        let dueDate0 = dueComponents0?.date
                        let dueDate1 = dueComponents1?.date

                        if dueDate0 != nil {
                            if dueDate1 != nil {
                                return dueDate0! < dueDate1!
                            } else {
                                return true
                            }
                        } else if dueDate1 != nil {
                            return false
                        }

                        if $0.priority != $1.priority {
                            return $0.priority > $1.priority
                        }

                        return $0.creationDate ?? Date() < $1.creationDate ?? Date()
                    }

                    DispatchQueue.main.async {
                        callback(sortedReminders, error)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    callback(nil, error)
                }
            }
        }
    }

    static func save(_ remindersToSave: [EKReminder]) throws {
        for each in remindersToSave {
            try eventStore.save(each, commit: false)
        }
        try eventStore.commit()
    }

    static func remove(_ remindersToRemove: [EKReminder]) throws {
        for each in remindersToRemove {
            try eventStore.remove(each, commit: false)
        }
        try eventStore.commit()
    }

    static func createReminder(_ item: ItemType, outline: OutlineType, reminderCalendar: EKCalendar) -> EKReminder {
        let clonedItem = outline.cloneItem(item, deep: false)
        let calendar = Calendar.current
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = reminderCalendar

        clonedItem.setAttribute("data-type", value: "note")

        if let start = clonedItem.attributeForName("data-start", className: "Date") as? Date {
            reminder.startDateComponents = calendar.dateComponents(in: calendar.timeZone, from: start)
            clonedItem.removeAttribute("data-start")
        }

        if let due = clonedItem.attributeForName("data-due", className: "Date") as? Date {
            reminder.dueDateComponents = calendar.dateComponents(in: calendar.timeZone, from: due)
            reminder.alarms = [EKAlarm(absoluteDate: due)]
            clonedItem.removeAttribute("data-due")
        }

        if item.hasAttribute("data-priority") {
            if let priority = clonedItem.attributeForName("data-priority", className: "Number") as? Int {
                reminder.priority = priority
            } else {
                reminder.priority = 1
            }
            clonedItem.removeAttribute("data-priority")
        }

        if item.hasAttribute("data-done") {
            reminder.isCompleted = true
            if let done = clonedItem.attributeForName("data-done", className: "Date") as? Date {
                reminder.completionDate = done
            }
            clonedItem.removeAttribute("data-done")
        }

        if item.firstChild != nil {
            reminder.notes = outline.serializeItems(item.descendants, options: nil)
        }

        reminder.title = clonedItem.body

        return reminder
    }

    static func createItem(_ reminder: EKReminder, outline: OutlineType) -> ItemType {
        let item = outline.createItem(reminder.title.replacingOccurrences(of: "\n", with: " "))

        item.setAttribute("data-type", value: "task")

        if let startDateComponents = reminder.startDateComponents, let start = Calendar.current.date(from: startDateComponents) {
            if startDateComponents != reminder.dueDateComponents {
                item.setAttribute("data-start", value: DateTime.format(dateTime: start, showMillisecondsIfNeeded: false, showSecondsIfNeeded: false))
            }
        }

        if let dueDateComponents = reminder.dueDateComponents, let due = Calendar.current.date(from: dueDateComponents) {
            item.setAttribute("data-due", value: DateTime.format(dateTime: due, showMillisecondsIfNeeded: false, showSecondsIfNeeded: false))
        }

        if reminder.priority != 0 {
            item.setAttribute("data-priority", value: reminder.priority)
        }

        if reminder.isCompleted {
            if let completion = reminder.completionDate {
                item.setAttribute("data-done", value: DateTime.format(dateTime: completion, showMillisecondsIfNeeded: false, showSecondsIfNeeded: false))
            } else {
                item.setAttribute("data-done", value: "")
            }
        }

        if let url = reminder.url {
            item.bodyContent += " \(url.absoluteString)"
        }

        if let notes = reminder.notes {
            if !notes.isEmpty {
                if let items = outline.deserializeItems(notes, options: nil) {
                    item.appendChildren(items)
                }
            }
        }

        return item
    }

    static func showReminderCalendarsPalette(_ outlineEditor: OutlineEditorType, placeholder: String, useDefaultList: Bool = false, allowsEmptySelection: Bool = false, allowsMultipleSelection: Bool = false, completionHandler: @escaping ((String?, ([EKCalendar])?, Error?) -> Void)) {
        fetchReminderCalendars { calendars, error in
            let defaultCalendar = self.eventStore.defaultCalendarForNewReminders()
            if var calendars = calendars, calendars.count > 0 {
                if let defaultCalendar = defaultCalendar {
                    if useDefaultList {
                        completionHandler("", [defaultCalendar], error)
                        return
                    }
                    
                    calendars.remove(at: calendars.firstIndex(of: defaultCalendar)!)
                    calendars.insert(defaultCalendar, at: 0)
                }

                var choices = [ChoicePaletteItem]()
                for each in calendars {
                    let appendText = each == defaultCalendar ? defaultListText : ""
                    let calendarItem = ChoicePaletteItem(type: "calendar", title: "\(each.title)\(appendText)")
                    calendarItem.representedObject = each
                    choices.append(calendarItem)
                }

                ChoicePaletteWindowController.showChoicePalette(
                    outlineEditor.outlineEditorViewController?.view.window,
                    placeholder: placeholder,
                    allowsEmptySelection: allowsEmptySelection,
                    allowsMultipleSelection: allowsMultipleSelection,
                    items: flattenChoicePaletteItemBranches(choices),
                    completionHandler: { string, choicePaletteItems in
                        if let string = string, let choicePaletteItems = choicePaletteItems {
                            completionHandler(string, choicePaletteItems.map { $0.representedObject as! EKCalendar }, error)
                        } else {
                            completionHandler(nil, nil, error)
                        }
                    }
                )
            } else {
                completionHandler(nil, nil, error)
            }
        }
    }

    static func showRemindersPalette(_ outlineEditor: OutlineEditorType, placeholder: String, useDefaultList: Bool = false, allowCompletedReminders: Bool = false, allowsEmptySelection: Bool = false, allowsMultipleSelection: Bool = false, completionHandler: @escaping ((String?, ([EKReminder])?, Error?) -> Void)) {
        fetchReminders(useDefaultList: useDefaultList, allowCompletedReminders: allowCompletedReminders) { reminders, error in
            if let error = error {
                completionHandler(nil, nil, error)
                return
            }

            if let reminders = reminders {
                var choices = [ChoicePaletteItem]()
                var idsToCalendarItems = [String: ChoicePaletteItem]()
                let defaultCalendar = self.eventStore.defaultCalendarForNewReminders()

                func calendarGroupItemForCalendar(calendar: EKCalendar) -> ChoicePaletteItem {
                    if let calendarItem = idsToCalendarItems[calendar.calendarIdentifier] {
                        return calendarItem
                    } else {
                        let isDefaultCalendar = calendar == defaultCalendar
                        let appendText = isDefaultCalendar ? defaultListText : ""
                        let title = calendar.title.replacingOccurrences(of: "\n", with: " ")
                        let calendarItem = ChoicePaletteItem(type: "group", title: "\(title)\(appendText)")
                        idsToCalendarItems[calendar.calendarIdentifier] = calendarItem
                        if isDefaultCalendar {
                            choices.insert(calendarItem, at: 0)
                        } else {
                            choices.append(calendarItem)
                        }
                        return calendarItem
                    }
                }

                func priorityString(_ priority: Int) -> String {
                    switch priority {
                    case 0:
                        return ""
                    case 1 ..< 5:
                        return "!!!"
                    case 5:
                        return "!!"
                    default:
                        return "!"
                    }
                }

                for each in reminders {
                    let calendarGroupItem = calendarGroupItemForCalendar(calendar: each.calendar)
                    let reminderTitle = each.title.replacingOccurrences(of: "\n", with: " ")
                    let reminderItem = ChoicePaletteItem(type: "reminder", title: reminderTitle)
                    let priority = priorityString(each.priority)
                    if !priority.isEmpty {
                        reminderItem.title = "\(priority) \(reminderItem.title)"
                    }
                    reminderItem.representedObject = each
                    calendarGroupItem.appendChild(reminderItem)
                }

                if choices.isEmpty {
                    let noRemindersItem = ChoicePaletteItem(type: "group", title: self.eventStore.defaultCalendarForNewReminders()?.title ?? "")
                    choices.append(noRemindersItem)
                }

                let now = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.doesRelativeDateFormatting = true
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short

                ChoicePaletteWindowController.showChoicePalette(
                    outlineEditor.outlineEditorViewController?.view.window,
                    placeholder: placeholder,
                    allowsEmptySelection: allowsEmptySelection,
                    allowsMultipleSelection: allowsMultipleSelection,
                    items: flattenChoicePaletteItemBranches(choices),
                    willDisplayTableCellViewHandler: { item, cell in
                        if let cell = cell as? ChoicePaletteTableCellView, let reminder = item.representedObject as? EKReminder {
                            if let dueDateComponents = reminder.dueDateComponents {
                                if let date = NSCalendar.current.date(from: dueDateComponents) {
                                    cell.detailTextField.objectValue = " \(dateFormatter.string(from: date))"
                                    if date < now {
                                        let attributedString = cell.detailTextField.attributedStringValueRemovingForegroundColor
                                        attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: reminder.calendar.color.withAlphaComponent(0.25), range: NSMakeRange(0, attributedString.length))
                                        cell.detailTextField?.attributedStringValue = attributedString
                                    }
                                } else {
                                    cell.detailTextField.objectValue = nil
                                }
                            } else {
                                cell.detailTextField.objectValue = nil
                            }

                            let priority = priorityString(reminder.priority)
                            if !priority.isEmpty {
                                if let attributedString = cell.titleTextField?.attributedStringValueRemovingForegroundColor {
                                    attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: reminder.calendar.color.withAlphaComponent(0.25), range: NSMakeRange(0, priority.utf16.count))
                                    cell.titleTextField?.attributedStringValue = attributedString
                                }
                            }

                            if reminder.isCompleted {
                                if let attributedString = cell.titleTextField?.attributedStringValueRemovingForegroundColor {
                                    attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, attributedString.length))
                                    cell.titleTextField?.attributedStringValue = attributedString
                                }
                            }
                        }
                    },
                    completionHandler: { string, choicePaletteItems in
                        if let string = string, let choicePaletteItems = choicePaletteItems {
                            completionHandler(string, choicePaletteItems.map { $0.representedObject as! EKReminder }, error)
                        } else {
                            completionHandler(nil, nil, error)
                        }
                    }
                )
            } else {
                completionHandler(nil, nil, error)
            }
        }
    }
}

extension EKReminder {
    var isLossyOnImport: Bool {
        if let alarms = alarms {
            if alarms.count > 1 {
                return true
            } else {
                let alarm = alarms[0]
                if alarm.structuredLocation != nil || alarm.emailAddress != nil {
                    return true
                }
            }
        }

        if hasAttendees {
            return true
        }

        if hasRecurrenceRules {
            return true
        }

        if location != nil {
            return true
        }

        return false
    }
}
