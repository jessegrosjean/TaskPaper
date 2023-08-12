Birch = require './birch'

Birch.commands.add 'outline-editor',

  ###
  'core:cut': (e) -> @cutSelection clipboardAsDatatransfer
  'core:copy': (e) -> @copySelection clipboardAsDatatransfer
  'core:paste': (e) -> @pasteToSelection clipboardAsDatatransfer

  'outline-editor:cut-opml': (e) -> @cutSelection(clipboardAsDatatransfer, ItemSerializer.OPMLMimeType)
  'outline-editor:copy-opml': (e) -> @copySelection(clipboardAsDatatransfer, ItemSerializer.OPMLMimeType)
  'outline-editor:paste-opml': (e) -> @pasteToSelection(clipboardAsDatatransfer, ItemSerializer.OPMLMimeType)

  'outline-editor:cut-text': (e) -> @cutSelection(clipboardAsDatatransfer, ItemSerializer.TEXTMimeType)
  'outline-editor:copy-text': (e) -> @copySelection(clipboardAsDatatransfer, ItemSerializer.TEXTMimeType)
  'outline-editor:paste-text': (e) -> @pasteToSelection(clipboardAsDatatransfer, ItemSerializer.TEXTMimeType)
  ###

  # Text Commands
  'outline-editor:undo': (e) -> @undo()
  'outline-editor:redo': (e) -> @redo()
  'outline-editor:backspace': (e) -> @backspace()
  'outline-editor:insert-tab': (e) -> @insertTab()
  'outline-editor:insert-backtab': (e) -> @insertBacktab()
  'outline-editor:newline': (e) -> @insertNewline()
  'outline-editor:newline-above': (e) -> @insertNewlineAbove()
  'outline-editor:newline-below': (e) -> @insertNewlineBelow()
  'outline-editor:newline-without-indent': (e) -> @insertNewlineWithoutIndent()
  'outline-editor:move-lines-right': (e) -> @moveLinesRight()
  'outline-editor:move-lines-left': (e) -> @moveLinesLeft()
  'outline-editor:move-lines-up': (e) -> @moveLinesUp()
  'outline-editor:move-lines-down': (e) -> @moveLinesDown()
  'outline-editor:group-lines': (e) -> @groupLines()
  'outline-editor:duplicate-lines': (e) -> @duplicateLines()
  'outline-editor:delete-lines': (e) -> @deleteLines()

  # Outline Commands

  'outline-editor:move-branches-left': (e) -> @moveBranchesLeft()
  'outline-editor:move-branches-right': (e) -> @moveBranchesRight()
  'outline-editor:move-branches-up': (e) -> @moveBranchesUp()
  'outline-editor:move-branches-down': (e) -> @moveBranchesDown()
  ###
  'outline-editor:delete-branches': (e) -> @deleteBranches(e?.items)
  'outline-editor:promote-child-branches': (e) -> @promoteChildBranches()
  'outline-editor:demote-trailing-sibling-branches': (e) -> @demoteTrailingSiblingBranches()
  'outline-editor:group-branches': (e) -> @groupBranches()
  'outline-editor:duplicate-branches': (e) -> @duplicateBranches()
  ###

  # Text Insert Commands

  'outline-editor:insert-date': (e, completedCallback) -> @insertDate(completedCallback)
  'outline-editor:tag-with': (e, completedCallback) -> @toggleUserSelectedAttribute(null, true, completedCallback)

  # Text Formatting Commands

  ###
  'outline-editor:toggle-abbreviation': (e) -> @toggleTextAttribute 'ABBR'
  'outline-editor:toggle-bold': (e) -> @toggleTextAttribute 'B'
  'outline-editor:toggle-citation': (e) -> @toggleTextAttribute 'CITE'
  'outline-editor:toggle-code': (e) -> @toggleTextAttribute 'CODE'
  'outline-editor:toggle-definition': (e) -> @toggleTextAttribute 'DFN'
  'outline-editor:toggle-emphasis': (e) -> @toggleTextAttribute 'EM'
  'outline-editor:toggle-italic': (e) -> @toggleTextAttribute 'I'
  'outline-editor:toggle-keyboard-input': (e) -> @toggleTextAttribute 'KBD'
  'outline-editor:toggle-inline-quote': (e) -> @toggleTextAttribute 'Q'
  'outline-editor:toggle-strikethrough': (e) -> @toggleTextAttribute 'S'
  'outline-editor:toggle-sample-output': (e) -> @toggleTextAttribute 'SAMP'
  'outline-editor:toggle-small': (e) -> @toggleTextAttribute 'SMALL'
  'outline-editor:toggle-strong': (e) -> @toggleTextAttribute 'STRONG'
  'outline-editor:toggle-subscript': (e) -> @toggleTextAttribute 'SUB'
  'outline-editor:toggle-superscript': (e) -> @toggleTextAttribute 'SUP'
  'outline-editor:toggle-underline': (e) -> @toggleTextAttribute 'U'
  'outline-editor:toggle-variable': (e) -> @toggleTextAttribute 'VAR'
  'outline-editor:clear-formatting': (e) -> @clearFormatting()
  ###

  'outline-editor:upper-case': (e) -> @upperCase()
  'outline-editor:lower-case': (e) -> @lowerCase()

  'outline-editor:fold': (e) -> @fold(e?.item, undefined, e?.allowFoldAncestor)
  'outline-editor:fold-completely': (e) -> @fold(e?.item, true)
  'outline-editor:expand': (e) -> @expand()
  'outline-editor:expand-completely': (e) -> @expand(null, true)
  'outline-editor:expand-all': (e) -> @setExpanded(@hoistedItem.descendants)
  'outline-editor:collapse': (e) -> @collapse()
  'outline-editor:collapse-completely': (e) -> @collapse(null, true)
  'outline-editor:collapse-all': (e) -> @setCollapsed(@hoistedItem.descendants)
  'outline-editor:increase-expansion-level': (e) -> @increaseExpansionLevel()
  'outline-editor:decrease-expansion-level': (e) -> @decreaseExpansionLevel()
  'outline-editor:home': (e) -> @hoistedItem = null
  'outline-editor:hoist': (e) -> @hoist()
  'outline-editor:unhoist': (e) -> @unhoist()
  'outline-editor:focus-in': (e) -> @focusIn(e?.item)
  'outline-editor:focus-out': (e) -> @focusOut()
  'outline-editor:refresh-search': (e) -> @refreshFilter()
  ###
  'outline-editor:reveal-item': (e) -> @revealItem()
  'outline-editor:open-link': (e) -> @openLink()
  'outline-editor:copy-link': (e) -> @copyLink()
  'outline-editor:edit-link': (e) -> @editLink()
  'outline-editor:remove-link': (e) -> @removeLink()
  'outline-editor:show-link-in-file-manager': (e) -> @showLinkInFileManager()
  'outline-editor:open-link-with-file-manager': (e) -> @openLinkWithFileManager()
  ###

  'outline-editor:select-word': (e) -> @selectWord()
  'outline-editor:select-sentence': (e) -> @selectSentence()
  'outline-editor:select-item': (e) -> @selectItem()
  'outline-editor:select-branch': (e) -> @selectBranch()
  'outline-editor:select-all': (e) -> @selectAll()
  'outline-editor:expand-selection': (e) -> @expandSelection()
  'outline-editor:contract-selection': (e) -> @contractSelection()
