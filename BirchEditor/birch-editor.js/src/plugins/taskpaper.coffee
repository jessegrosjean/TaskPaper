{ Item }  = require 'birch-outline'
moment = require 'moment'
Birch = require '../birch'

archiveDone = (editor) ->
  outline = editor.outline
  selection = editor.selection
  startItem = selection.startItem
  endItem = selection.endItem
  archive = outline.evaluateItemPath("//@text = Archive:")[0]
  doneItems = Item.getCommonAncestors(outline.evaluateItemPath("//@done except //@text = Archive://@done"))
  removeExtraTags = Birch.preferences.get('BRemoveExtraTagsWhenArchivingDone')
  addProjectTag = Birch.preferences.get('BIncludeProjectWhenArchivingDone')

  outline.groupUndoAndChanges ->
    unless archive
      outline.root.appendChildren(archive = outline.createItem('Archive:'))
    for each in doneItems
      if removeExtraTags
        for eachName in each.attributeNames
          if eachName.indexOf('data-') is 0 and eachName isnt 'data-type' and eachName isnt 'data-done'
            each.removeAttribute(eachName)
      if addProjectTag
        if projects = (eachProject.bodyContentString for eachProject in outline.evaluateItemPath('ancestor::@type=project', each)).join(' / ')
          each.setAttribute('data-project', projects)
      if (each is startItem or each.contains(startItem)) or (each is endItem or each.contains(endItem))
        if previousItem = editor.getPreviousDisplayedItem(startItem)
          selection = startItem: previousItem, startOffset: -1
        else
          selection = start: 0
    archive.insertChildrenBefore(doneItems, archive.firstChild)
  editor.moveSelectionToItems(selection)

toggleDateAttribute = (editor, placeholder, tag, completedCallback) ->
  attributeName = "data-#{tag}"
  items = editor.selection.displayedSelectedItems
  if editor.hasAttribute(attributeName, items)
    editor.setAttribute(items, attributeName, null)
    completedCallback?(true)
  else
    editor.getDateFromUser placeholder, "@#{tag}(%@)", (date) ->
      if date
        editor.toggleAttribute(attributeName, Birch.DateTime.format(date, false, false), items)
        completedCallback?(true)
      else
        completedCallback?(false)

clearTags = (editor) ->
  selection = editor.selection
  editor.outline.groupUndoAndChanges ->
    for each in selection.displayedSelectedItems
      for eachName in each.attributeNames
        if eachName.indexOf('data-') is 0 and eachName isnt 'data-type'
          each.removeAttribute(eachName)
  editor.moveSelectionToItems(selection)

importReminders = (editor, completedCallback) ->
  editor.nativeEditor.importRemindersWithCallback(completedCallback)

importReminderCopies = (editor, completedCallback) ->
  editor.nativeEditor.importReminderCopiesWithCallback(completedCallback)

exportToReminders = (editor, completedCallback) ->
  editor.nativeEditor.exportToRemindersWithCallback(completedCallback)

exportCopyToReminders = (editor, completedCallback) ->
  editor.nativeEditor.exportCopyToRemindersWithCallback(completedCallback)

module.exports = () ->

  Birch.commands.override 'outline-editor',
    # This doesn't seem right ... insert-Tab command should "insert tab"?
    'outline-editor:insert-tab': (e) -> @moveLinesRight()
    'outline-editor:insert-backtab': (e) -> @moveLinesLeft()
    'outline-editor:backspace': (e) ->
      selection = @selection
      if selection.length is 0 and selection.startOffset is 0 and selection.startItem.depth > @hoistedItem.depth + 1
        @moveLinesLeft()
      else
        @backspace(e)

  Birch.commands.add 'outline-editor',
    'outline-editor:format-project': (e) -> @setAttribute(null, 'data-type', 'project')
    'outline-editor:format-task': (e) -> @setAttribute(null, 'data-type', 'task')
    'outline-editor:format-note': (e) -> @setAttribute(null, 'data-type', 'note')
    'outline-editor:toggle-done': (e) ->
      if Birch.preferences.get('BIncludeDateWhenTaggingDone')
        value = moment().format('YYYY-MM-DD')
      @toggleAttribute('data-done', value)
    'outline-editor:toggle-today': (e) -> @toggleAttribute('data-today')
    'outline-editor:toggle-start': (e, completedCallback) ->
      toggleDateAttribute(@, 'Start Date', 'start', completedCallback)
    'outline-editor:toggle-due': (e, completedCallback) ->
      toggleDateAttribute(@, 'Due Date', 'due', completedCallback)
    'outline-editor:remove-tags': (e) -> clearTags(@)
    'outline-editor:archive-done': (e) -> archiveDone(@)
    'outline-editor:new-task': (e) ->
      @focus()
      task = @insertItem('- New Task')
      @moveSelectionToItems(task, 2, task, task.bodyString.length)
    'outline-editor:new-note': (e) ->
      @focus()
      note = @insertItem('New Note')
      @moveSelectionToItems(note, 0, note, note.bodyString.length)
    'outline-editor:new-project': (e) ->
      @focus()
      project = @insertItem('New Project:')
      @moveSelectionToItems(project, 0, project, project.bodyString.length - 1)
    'outline-editor:import-reminders': (e, completedCallback) ->
      importReminders(@, completedCallback)
    'outline-editor:import-reminder-copies': (e, completedCallback) ->
      importReminderCopies(@, completedCallback)
    'outline-editor:export-to-reminders': (e, completedCallback) ->
      exportToReminders(@, completedCallback)
    'outline-editor:export-copy-to-reminders': (e, completedCallback) ->
      exportCopyToReminders(@, completedCallback)
