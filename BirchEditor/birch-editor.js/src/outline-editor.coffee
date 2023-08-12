{ Outline, Item, AttributedString, Mutation, ItemSerializer, ItemPath, DateTime, shortid, util }  = require 'birch-outline'
{Emitter, CompositeDisposable, Disposable} = require 'event-kit'
OutlineEditorNative = require './outline-editor-native'
StyleSheet = require './style-sheet'
ItemBuffer = require './item-buffer'
stringHash = require 'string-hash'
flatten = require 'reduce-flatten'
Selection = require './selection'
_ = require 'underscore-plus'
moment = require 'moment'
Birch = require './birch'
assert = util.assert

require './outline-editor-commands'

# Public: Maps an {Outline} into an editable text buffer.
#
# The outline editor maintains the hoisted item, folded items, filter path,
# and selected items. It uses this state to determine which items are
# displayed and selected in the text buffer.
class OutlineEditor

  ###
  Section: Construction
  ###

  constructor: (outline, @styleSheet=new StyleSheet(), @nativeEditor) ->
    @id = shortid()
    @emitter = new Emitter
    @isUpdatingNativeBuffer = 0
    @isUpdatingItemBuffer = 0
    @subscriptions = new CompositeDisposable
    @itemBuffer = new ItemBuffer(outline, this)
    @nativeEditor ?= new OutlineEditorNative(@)
    @styleSheetComputedStyleCache = {}
    @maintainScrollPointCount = 0

    @subscriptions.add @itemBuffer.onDidBeginChanges =>
      @nativeEditor.beginEditing()

    @subscriptions.add @itemBuffer.onDidChange (e) =>
      if not @isUpdatingItemBuffer
        @isUpdatingNativeBuffer++
        nsrange = location: e.location, length: e.replacedLength
        @nativeEditor.replaceCharactersInRangeWithString(nsrange, e.insertedString)
        @isUpdatingNativeBuffer--

    @subscriptions.add @itemBuffer.onDidEndChanges =>
      @nativeEditor.endEditing()

    @subscriptions.add @outline.onWillReload @_outlineWillReload.bind(this)
    @subscriptions.add @outline.onDidReload @_outlineDidReload.bind(this)

    @subscriptions.add @itemBuffer.onDidDestroy =>
      @destroy()

    undoManager = @outline.undoManager

    @subscriptions.add undoManager.onDidOpenUndoGroup =>
      if not undoManager.isUndoing and not undoManager.isRedoing
        undoManager.setUndoGroupMetadata("#{@id}undoSelection", @selection)

    @subscriptions.add undoManager.onWillUndo (undoGroupMetadata) =>
      undoManager.setUndoGroupMetadata("#{@id}redoSelection", @selection)
      @_beginMaintainScrollPoint()

    @subscriptions.add undoManager.onDidUndo (undoGroupMetadata) =>
      @forceSelectionDisplayed(undoGroupMetadata?["#{@id}undoSelection"])
      @_endMaintainScrollPoint()
      @scrollRangeToVisible()

    @subscriptions.add undoManager.onDidOpenUndoGroup =>
      if not undoManager.isUndoing and not undoManager.isRedoing
        undoManager.setUndoGroupMetadata("#{@id}undoSelection", @selection)

    @subscriptions.add undoManager.onWillRedo (undoGroupMetadata) =>
      @_beginMaintainScrollPoint()

    @subscriptions.add undoManager.onDidRedo (undoGroupMetadata) =>
      @forceSelectionDisplayed(undoGroupMetadata?["#{@id}redoSelection"])
      @_endMaintainScrollPoint()
      @scrollRangeToVisible()

    @editorStyleElement =
      parentNode: null
      computedStyleKeyPath: null
      tagName: 'editor'
      attributes: {}

    @itemStyleElement =
      parentNode: @editorStyleElement
      computedStyleKeyPath: null
      tagName: 'item'
      attributes: {}
      item: null

    @runStyleElement =
      parentNode: @itemStyleElement
      computedStyleKeyPath: null
      tagName: 'run'
      attributes: {}

    @hoistedItem = @outline.root

  destroy: ->
    unless @destroyed
      @itemBuffer.destroy()
      @subscriptions.dispose()
      @emitter.emit 'did-destroy'
      @destroyed = true

  ###
  Section: Finding Outline Editors
  ###

  @outlineEditors = []

  # Public: Retrieves all open {OutlineEditor}s.
  #
  # Returns an {Array} of {OutlineEditor}s.
  @getOutlineEditors: ->
    @outlineEditors.slice()

  # API backward, compatibility, replaced by getOutlineEditorsForOutline
  @getOutlineEditorForOutline: (outline) ->
    outlineEditors = []
    for each in @outlineEditors
      if each.outline is outline
        outlineEditors.push(each)
    outlineEditors

  # Public: Return {Array} of all {OutlineEditor}s associated with the given
  # {Outline}.
  #
  # - `outline` Edited {Outline}.
  @getOutlineEditorsForOutline: (outline) ->
    outlineEditors = []
    for each in @outlineEditors
      if each.outline is outline
        outlineEditors.push(each)
    outlineEditors

  @addOutlineEditor: (outlineEditor, options={}) ->
    @addOutlineEditorAtIndex(outlineEditor, @outlineEditors.length, options)

  @addOutlineEditorAtIndex: (outlineEditor, index, options={}) ->
    @outlineEditors.splice(index, 0, outlineEditor)
    outlineEditor.onDidDestroy =>
      @removeOutlineEditor(outlineEditor)
    outlineEditor

  @removeOutlineEditor: (outlineEditor) ->
    index = @outlineEditors.indexOf(outlineEditor)
    @removeOutlineEditorAtIndex(index) unless index is -1

  @removeOutlineEditorAtIndex: (index, options={}) ->
    [outlineEditor] = @outlineEditors.splice(index, 1)
    outlineEditor?.destroy()

  ###
  Section: Events
  ###

  onDidChangeSelection: (callback) ->
    @emitter.on 'did-change-selection', callback

  onDidChangeHoistedItem: (callback) ->
    @itemBuffer.onDidChangeHoistedItem(callback)

  onDidChangeFocusedItem: (callback) ->
    @itemBuffer.onDidChangeFocusedItem(callback)

  onDidChangeItemPathFilter: (callback) ->
    @itemBuffer.onDidChangeItemPathFilter(callback)

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  ###
  Section: Outline
  ###

  # Public: {Outline} that is edited.
  outline: null
  Object.defineProperty @::, 'outline',
    get: -> @itemBuffer.outline

  ###
  Section: State
  ###

  hoist: (item) ->
    @hoistedItem = item ? @selection.startItem

  unhoist: ->
    @hoistedItem = @outline.root

  focusIn: (item) ->
    item = item ? @selection.startItem
    if @focusedItem is item and item.hasChildren
      @hoistedItem = item
    else
      @focusedItem = item ? @selection.startItem

  focusOut: ->
    selection = @selection
    focusedItem = @focusedItem
    startItem = selection.startItem
    scrollDocumentY = @scrollPoint.y
    selectedDocumentY = @getRectForRange(selection.location, 1).y
    selectedWindowY = selectedDocumentY - scrollDocumentY

    if focusedItem
      newFocusItem = focusedItem.parent
    else
      newFocusItem = @hoistedItem

    if newFocusItem.isOutlineRoot
      @hoistedItem = newFocusItem
    else
      @focusedItem = newFocusItem

    startItem = @getDisplayedSelfOrAncestor(startItem)
    @moveSelectionToItems(startItem)
    scrollDocumentY = @scrollPoint.y
    selectedDocumentY = @getRectForRange(@selection.location, 1).y
    newSelectedWindowY = selectedDocumentY - scrollDocumentY
    @scrollBy(0, newSelectedWindowY - selectedWindowY)

  # Public: Root of all items displayed in the text buffer.
  hoistedItem: null
  Object.defineProperty @::, 'hoistedItem',
    get: -> @itemBuffer.hoistedItem
    set: (item) -> @editorState = hoistedItem: item

  # Public: Focused item in the text buffer. Similar to {::hoistedItem}, but
  # the hoisted item is never displayed in the text buffer, while
  # {::focusedItem} is displayed (and temporarily expanded) to show any
  # children.
  focusedItem: null
  Object.defineProperty @::, 'focusedItem',
    get: -> @itemBuffer.focusedItem
    set: (item) -> @editorState = focusedItem: item

  # Public: Item path formatted {String}. When set only matching items display in the text buffer.
  itemPathFilter: null
  Object.defineProperty @::, 'itemPathFilter',
    get: -> @itemBuffer.itemPathFilter
    set: (itemPathFilter) -> @editorState = itemPathFilter: itemPathFilter

  Object.defineProperty @::, 'editorState',
    get: -> @itemBuffer.bufferState
    set: (editorState) ->
      if @itemPathFilter
        @editorStyleElement.attributes['searching'] = null
      else
        @editorStyleElement.attributes['searching'] = 'true'
      @maintainScrollPoint =>
        @itemBuffer.bufferState = editorState
      @moveSelectionToRange(0, 0)
      @scrollRangeToVisible()

  refreshFilter: ->
    selection = @selection
    selection.prepareForMove()
    @maintainScrollPoint =>
      @itemBuffer.bufferState = @itemBuffer.bufferState
    selection.restoreAfterMove()
    @moveSelectionToItems(selection)
    @scrollRangeToVisible()

  revealItem: ->
    selection = @selection
    selectedItems = selection.displayedSelectedItems
    selection.prepareForMove()
    @editorState =
      hoistedItem: null
      itemPathFilter: ''
    @forceDisplayed(selectedItems, true)
    selection.restoreAfterMove()
    @moveSelectionToItems(selection)
    @scrollRangeToVisible()

  ###
  Section: Folding Items
  ###

  # Public: Toggle folding status of current selection.
  fold: (items, completely=false, allowCollapseAncestor=true) ->
    items ?= @selection.displayedSelectedItems
    unless Array.isArray(items)
      items = [items]

    branches = Item.getCommonAncestors(items)
    parentBranches = (each for each in branches when each.hasChildren)

    if parentBranches.length
      expandedParentBranches = (each for each in parentBranches when @isExpanded(each))
      if parentBranches.length is expandedParentBranches.length
        @collapse(parentBranches, completely, allowCollapseAncestor)
      else
        @expand(parentBranches, completely, allowCollapseAncestor)
    else if allowCollapseAncestor
      @collapse(items, completely)

  expand: (items, completely=false, allowExpandAncestor=true) ->
    items ?= @selection.displayedSelectedItems
    unless Array.isArray(items)
      items = [items]

    branches = Item.getCommonAncestors(items)
    parentBranches = (each for each in branches when each.hasChildren)
    unless parentBranches.length
      if ancestor = @getDisplayedAncestor(items[0])
        parentBranches = [ancestor]

    if completely
      @setExpandedState(parentBranches, true, true)
    else
      expandableParentBranches = (each for each in parentBranches when not @isExpanded(each))
      if expandableParentBranches.length
        @setExpandedState(expandableParentBranches, true)

  collapse: (items, completely=false, allowCollapseAncestor=true) ->
    items ?= @selection.displayedSelectedItems
    unless Array.isArray(items)
      items = [items]

    branches = Item.getCommonAncestors(items)
    parentBranches = (each for each in branches when each.hasChildren)
    unless parentBranches.length
      if ancestor = @getDisplayedAncestor(items[0])
        selection = @selection
        @moveSelectionToItems(ancestor, ancestor.bodyString.length)
        @collapse(null, completely)
        return

    if completely
      @setExpandedState(parentBranches, false, true)
    else
      collapsableParentBranches = (each for each in parentBranches when not @isCollapsed(each))
      if collapsableParentBranches.length
        @setExpandedState(collapsableParentBranches, false)

  increaseExpansionLevel: ->
    @setExpansionLevel(@getExpansionLevel() + 1)

  decreaseExpansionLevel: ->
    @setExpansionLevel(@getExpansionLevel() - 1)

  getExpansionLevel: ->
    maxCollapsedDepth = Number.MAX_VALUE
    maxItemDepth = 0

    @itemBuffer.iterateLines 0, @itemBuffer.getLineCount(), (line) =>
      item = line.item
      depth = item.depth
      maxItemDepth = Math.max(depth, maxItemDepth)
      if item.hasChildren and not @isExpanded(item)
        maxCollapsedDepth = Math.max(depth, maxCollapsedDepth)

    if maxCollapsedDepth is Number.MAX_VALUE
      maxItemDepth
    else
      maxCollapsedDepth

  setExpansionLevel: (level) ->
    items = @hoistedItem.descendants
    @maintainScrollPoint =>
      @itemBuffer.updateIndex =>
        @setCollapsed((item for item in items when item.depth >= level))
        @setExpanded((item for item in items when item.depth < level))

  # Public: Return true of the given item is expanded.
  #
  # - `item` {Item} to check.
  isExpanded: (item) ->
    @itemBuffer.isExpanded(item)

  # Public: Return true of the given item has some of its children visible and
  # others hidden.
  #
  # - `item` {Item} to check.
  isFiltered: (item) ->
    @itemBuffer.isFiltered(item)

  # Public: Return true of the given item is collapsed.
  #
  # - `item` {Item} to check.
  isCollapsed: (item) ->
    @itemBuffer.isCollapsed(item)

  isExplicitlyCollapsed: (item) ->
    @itemBuffer.isExplicitlyCollapsed(item)

  getItemExpandedState: (item) ->
    @itemBuffer.getItemExpandedState(item)

  # Public: Expand the given item(s).
  #
  # - `items` {Item} or {Array} of items to expand.
  setExpanded: (items) ->
    @setExpandedState items, true

  # Public: Collapse the given item(s).
  #
  # - `items` {Item} or {Array} of items to collapse.
  setCollapsed: (items) ->
    @setExpandedState items, false

  setExpandedState: (items, expand, completely=false) ->
    selection = @selection
    items ?= selection.displayedSelectedItems
    unless Array.isArray(items)
      items = [items]

    if completely
      items = Item.getCommonAncestors(items).map (each) -> each.branchItems
      items = items.reduce(flatten, [])

    @maintainScrollPoint =>
      @itemBuffer.setExpandedState(items, expand, completely)

    unless @itemBuffer.isChanging
      @moveSelectionToItems(selection)

  ###
  Section: Displayed Items
  ###

  # Public: Determine if an {Item} is displayed in the editor's text buffer. A
  # displayed item isn't neccessarily visible because it might be scrolled off
  # screen. Displayed means that its body text is present and editable in the
  # buffer.
  #
  # - `item` {Item} to test.
  #
  # Returns {Boolean} indicating if item is displayed.
  isDisplayed: (item) ->
    @itemBuffer.isDisplayed(item)

  # Public: Force the given {Item} to display in the editor's text buffer,
  # expanding ancestors, removing filters, and unhoisting items as needed.
  #
  # - `item` {Item} to make displayed.
  # - `showAncestors` (optional) {Boolean} defaults to false.
  forceDisplayed: (item, showAncestors=false) ->
    @itemBuffer.forceDisplayed(item, showAncestors)

  # Public: Remove the given {Item}(s) from display in the editor's text
  # buffer, leaving all other items in place.
  #
  # - `item` {Item}(s) to hide.
  # - `hideDescendants` (optional) {Boolean} defaults to false.
  forceHidden: (items, hideDescendants=false) ->
    @itemBuffer.forceHidden(items, hideDescendants)

  forceSelectionDisplayed: (selection) ->
    if selection?.startItem
      @forceDisplayed(selection.startItem)
      @forceDisplayed(selection.endItem)
      @moveSelectionToItems(
        selection.startItem,
        selection.startOffset,
        selection.endItem,
        selection.endOffset)
    else
      @moveSelectionToRange(0, 0)

  # Public: {Array} of visible {Item}s in editor (readonly).
  displayedItems: null
  Object.defineProperty @::, 'displayedItems',
    get: -> @itemBuffer.displayedItems

  # Public: First displayed {Item} in editor (readonly).
  firstDisplayedItem: null
  Object.defineProperty @::, 'firstDisplayedItem',
    get: -> @itemBuffer.firstDisplayedItem

  # Public: Last displayed {Item} in editor (readonly).
  lastDisplayedItem: null
  Object.defineProperty @::, 'lastDisplayedItem',
    get: -> @itemBuffer.lastDisplayedItem

  numberOfDisplayedItems: null
  Object.defineProperty @::, 'numberOfDisplayedItems',
    get: -> @itemBuffer.getLineCount()

  heightOfDisplayedItems: null
  Object.defineProperty @::, 'heightOfDisplayedItems',
    get: -> @itemBuffer.getHeight()

  getDisplayedItemAtIndex: (index) ->
    @itemBuffer.getLine(index).item

  getDisplayedItemYOffsetAtIndex: (index) ->
    @itemBuffer.getLine(index).getYOffset()

  getDisplayedItemIndexAtYOffset: (yOffset) ->
    @itemBuffer.getSpanInfoAtYOffset(yOffset).spanIndex

  setDisplayedItemHeightAtIndex: (height, index) ->
    @itemBuffer.getLine(index).setHeight(height)

  # Public: Returns next displayed {Item} relative to given item.
  #
  # - `item` {Item}
  getNextDisplayedItem: (item) ->
    @itemBuffer.getNextDisplayedItem(item)

  # Public: Returns previous displayed {Item} relative to given item.
  #
  # - `item` {Item}
  getPreviousDisplayedItem: (item) ->
    @itemBuffer.getPreviousDisplayedItem(item)

  getDisplayedAncestor: (item) ->
    @itemBuffer.getDisplayedAncestor(item)

  getDisplayedSelfOrAncestor: (item) ->
    @itemBuffer.getDisplayedSelfOrAncestor(item)

  getPreviousDisplayedSibling: (item) ->
    @itemBuffer.getPreviousDisplayedSibling(item)

  getNextDisplayedSibling: (item) ->
    @itemBuffer.getNextDisplayedSibling(item)

  getFirstDisplayedDescendant: (item) ->
    @itemBuffer.getFirstDisplayedDescendant(item)

  getLastDisplayedDescendant: (item) ->
    @itemBuffer.getLastDisplayedDescendant(item)

  getFirstDisplayedDescendantOrSelf: (item) ->
    @itemBuffer.getFirstDisplayedDescendantOrSelf(item)

  getLastDisplayedDescendantOrSelf: (item) ->
    @itemBuffer.getLastDisplayedDescendantOrSelf(item)

  getDisplayedBodyCharacterRange: (item) ->
    @itemBuffer.getDisplayedBodyCharacterRange(item)

  getDisplayedBranchCharacterRange: (item) ->
    @itemBuffer.getDisplayedBranchCharacterRange(item)

  invalidateItem: (item, range) ->
    if not range
      range = @getDisplayedBodyCharacterRange(item)
      if range
        range.length += 1 # Extend to include newline
        @invalidateRange(range)

  invalidateRange: (range) ->
    @nativeEditor?.invalidateRange(range)

  ###
  Section: Computed Styles
  ###

  getComputedStyle: ->
    @styleSheet.getComputedStyleForElement(@editorStyleElement, @styleSheetComputedStyleCache)

  getComputedStyleKeyPathForItem: (item) ->
    attributes = Object.assign({}, item.attributes ? {})
    attributes['depth'] = item.depth
    attributes['bodyContent'] = item.bodyContentString
    if item is @focusedItem
      attributes['focused'] = 'true'
    if item is @mouseOverItem
      attributes['mouseOver'] = 'true'
    if item is @mouseOverItemHandle
      attributes['mouseOverHandle'] = 'true'
    attributes[@getItemExpandedState(item)] = 'true'
    if attributes['leaf'] and item.bodyString.length is 0
      attributes['empty'] = 'true'

    @itemStyleElement.attributes = attributes
    @itemStyleElement.item = item
    @itemStyleElement.computedStyleKeyPath = null
    @styleSheet.getComputedStyleKeyPathForElement(@itemStyleElement, @styleSheetComputedStyleCache)

  getComputedStyleKeyPathForItemRun: (item, run) ->
    assert(@itemStyleElement.item is item)
    @runStyleElement.attributes = run.attributes ? {}
    @runStyleElement.computedStyleKeyPath = null
    @styleSheet.getComputedStyleKeyPathForElement(@runStyleElement, @styleSheetComputedStyleCache)

  getComputedStyleMetadataForItemIDs: (ids) ->
    hoistedDepth = @hoistedItem.depth
    styles = []
    for each in @outline.getItemsForIDs(ids)
      styles.push(each.id)
      styles.push(each.getAttribute('data-type') ? 'notype')
      styles.push(each.depth - hoistedDepth)
      styles.push(@getComputedStyleKeyPathForItem(each))
      runs = each.bodyHighlightedAttributedString.getRuns()
      styles.push(runs.length)
      for run in runs
        styles.push(@getComputedStyleKeyPathForItemRun(each, run))
        styles.push(run.attributes.link ? '')
        styles.push(run.getLength())
    styles

  Object.defineProperty @::, 'mouseOverItem',
    get: ->
      @_mouseOverItem
    set: (newItem) ->
      oldItem = @_mouseOverItem

      if newItem is oldItem
        return
      else
        @_mouseOverItem = newItem

      @nativeEditor?.beginEditing()
      if oldItem
        @invalidateItem(oldItem)
      if newItem
        @invalidateItem(newItem)
      @nativeEditor?.endEditing()

  Object.defineProperty @::, 'mouseOverItemHandle',
    get: ->
      @_mouseOverItemHandle
    set: (newItem) ->
      oldItem = @_mouseOverItemHandle

      if newItem is oldItem
        return
      else
        @_mouseOverItemHandle = newItem

      @nativeEditor?.beginEditing()
      if oldItem
        @invalidateItem(oldItem)
      if newItem
        @invalidateItem(newItem)
      @nativeEditor?.endEditing()

  styleSheet: null
  Object.defineProperty @::, 'styleSheet',
    get: -> @_styleSheet
    set: (newStyleSheet) ->
      if @_styleSheet isnt newStyleSheet
        @_styleSheet = newStyleSheet ? new StyleSheet
        @styleSheetComputedStyleCache = {}
        @editorStyleElement?.computedStyle = null
        @editorStyleElement?.computedStyleKeyPath = null
        @itemStyleElement?.computedStyle = null
        @itemStyleElement?.computedStyleKeyPath = null
        @runStyleElement?.computedStyle = null
        @runStyleElement?.computedStyleKeyPath = null
        @nativeEditor?.beginEditing()
        @invalidateRange(location: 0, length: @textLength)
        @nativeEditor?.endEditing()

  ###
  Section: Text Buffer
  ###

  # Public: Read-only text buffer {Number} length.
  textLength: null
  Object.defineProperty @::, 'textLength',
    get: -> @itemBuffer?.getLength() ? 0

  # Public: Translate from a text buffer location to an {Item} offset.
  #
  # - `location` Text buffer character {Number} location.
  #
  # Returns {Object} with `item` and `offset` properties.
  getItemOffsetForLocation:(location) ->
    @itemBuffer.getItemOffsetForLocation(location)

  # Public: Translate from item offset to the nearest valid text buffer
  # location.
  #
  # - `item` {Item} to lookup.
  # - `offset` {Number} offset into the items text.
  #
  # Returns text buffer character offset {Number}.
  getLocationForItemOffset: (item, offset) ->
    @itemBuffer.getLocationForItemOffset(item, offset)

  getItemIDsInRange: (location, length) ->
    ids = []
    spans = @itemBuffer.getSpansInRange(location, length, true)
    for each in spans
      ids.push(each.item.id)
    ids

  # Public: Get text in the given range.
  #
  # - `location` {Number} character location.
  # - `length` {Number} character range length.
  getTextInRange: (location, length) ->
    @itemBuffer.substr(location, length)

  insertText: (string) ->
    selection = @selection
    @replaceRangeWithString(selection.location, selection.length, string)

  ###
  insertText: (insertedText) ->
      selectionRange = @selection
      undoManager = @outline.undoManager

      if selectionRange.isTextMode
        if not (insertedText instanceof AttributedString)
          insertedText = new AttributedString(insertedText)
          insertedText.addAttributesInRange(@getTypingFormattingTags(), 0, -1)

        focusItem = selectionRange.focusItem
        startOffset = selectionRange.startOffset
        endOffset = selectionRange.endOffset

        focusItem.replaceBodyTextInRange(insertedText, startOffset, endOffset - startOffset)
        @moveSelectionRange(focusItem, startOffset + insertedText.length)
      else
        @moveSelectionRange(@insertItem(insertedText))
  ###

  # Public: Replace the given range with a string.
  #
  # - `location` {Number} character location.
  # - `length` {Number} character range length.
  # - `string` {String} to insert.
  replaceRangeWithString: (location, length, string, fromNativeEditorHack) ->
    if not @isUpdatingNativeBuffer
      outline = @outline
      if fromNativeEditorHack
        @isUpdatingItemBuffer++
      else
        @_beginMaintainScrollPoint()
      @itemBuffer.updateOutline =>
        outline.groupUndoAndChanges =>
          @itemBuffer.replaceRange(location, length, string)
      if fromNativeEditorHack
        @isUpdatingItemBuffer--
      else
        @_endMaintainScrollPoint()
        @moveSelectionToRange(location + string.length)
        @scrollRangeToVisible()

  # Public: Replace the given range with a items.
  #
  # - `location` {Number} character location.
  # - `length` {Number} character range length.
  # - `items` {Array} of {Item}s to insert.
  replaceRangeWithItems: (location, length, items) ->
    outline = @outline
    undoManager = outline.undoManager
    insertAtItemOffset = @getItemOffsetForLocation(location)
    insertAtItem = insertAtItemOffset?.item
    items = Item.flattenItemHiearchy(items)
    itemsString = (each.bodyString for each in items).join('\n')
    itemSpans = (@itemBuffer.createSpanForItem(each) for each in items)

    @maintainScrollPoint =>
      @itemBuffer.updateOutline =>
        outline.groupUndoAndChanges =>
          if insertAtItem
            for each in items
              each.indent += (insertAtItem.depth - 1)
          @itemBuffer.replaceRange(location, length, itemsString, itemSpans)

    @moveSelectionToRange(location + itemsString.length)
    @scrollRangeToVisible()

  ###
  Section: Selection
  ###

  # Public: Read-only {Selection} snapshot.
  selection: null
  Object.defineProperty @::, 'selection',
    get: ->
      nsRange = @nativeEditor.selectedRange
      start = nsRange.location
      end = nsRange.location + nsRange.length
      startItemOffset = @getItemOffsetForLocation(start)
      if start is end
        endItemOffset = startItemOffset
      else
        endItemOffset = @getItemOffsetForLocation(end)
      new Selection(@, start, end, startItemOffset.item, startItemOffset.offset, endItemOffset.item, endItemOffset.offset)

  # Public: Set selection by character locations in text buffer.
  #
  # - `headLocation` Selection focus character {Number} location.
  # - `anchorLocation` (optional) Selection anchor character {Number} location.
  moveSelectionToRange: (headLocation, anchorLocation, selectionAffinity) ->
    @typingAttributes = null
    anchorLocation ?= headLocation
    headLocation = Math.max(0, headLocation)
    headLocation = Math.min(headLocation, @textLength)
    anchorLocation = Math.max(0, anchorLocation)
    anchorLocation = Math.min(anchorLocation, @textLength)

    # Don't allow collapsed select at end of buffer in trailing newline
    # region.
    if anchorLocation > 0 and anchorLocation is headLocation and anchorLocation is @itemBuffer.getLength()
      anchorLocation--
      headLocation--

    location = Math.min(headLocation, anchorLocation)
    length = Math.abs(anchorLocation - headLocation)

    nsRange = @nativeEditor.selectedRange
    if location isnt nsRange.location or length isnt nsRange.length
      @nativeEditor.selectedRange =
        location: location
        length: length

  # Public: Set selection by {Item}.
  #
  # - `headItem` Selection head {Item}
  # - `headOffset` (optional) Selection head offset index. Or `undefined`
  #    when selecting at item level.
  # - `anchorItem` (optional) Selection anchor {Item}
  # - `anchorOffset` (optional) Selection anchor offset index. Or `undefined`
  #    when selecting at item level.
  moveSelectionToItems: (headItem, headOffset, anchorItem, anchorOffset, selectionAffinity) ->
    if headItem?.startItem? or headItem?.start?
      selection = headItem
      headItem = selection.headItem
      headOffset = selection.headOffset
      anchorItem = selection.anchorItem
      anchorOffset = selection.anchorOffset
      headItem ?= selection.startItem
      headOffset ?= selection.startOffset
      anchorItem ?= selection.endItem
      anchorOffset ?= selection.endOffset
      start = selection.start
      end = selection.end

    if not headItem
      @moveSelectionToRange(start ? 0, end ? 0)
      return

    headOffset ?= 0
    if headOffset is -1
      headOffset = headItem.bodyString.length
    if anchorItem
      anchorOffset ?= 0
      if anchorOffset is -1
        anchorOffset = anchorItem.bodyString.length
    else
      anchorItem = headItem
      anchorOffset = headOffset

    headOffset = Math.min(headOffset, headItem.bodyString.length + 1)
    anchorOffset = Math.min(anchorOffset, anchorItem.bodyString.length + 1)

    focusLocation = @getLocationForItemOffset(headItem, headOffset) ? 0
    anchorLocation = @getLocationForItemOffset(anchorItem, anchorOffset) ? focusLocation

    @moveSelectionToRange(focusLocation, anchorLocation)

  selectWord: ->
    @nativeEditor.selectWord()

  selectSentence: ->
    @nativeEditor.selectSentence()

  selectItem: ->
    @moveSelectionToItems(@selection.selectionByExtendingToItem())

  selectBranch: ->
    @moveSelectionToItems(@selection.selectionByExtendingToBranch())

  selectAll: ->
    @moveSelectionToRange(0, @textLength)

  expandSelection: ->
    @nativeEditor.expandSelection()

  contractSelection: ->
    @nativeEditor.contractSelection()

  focus: ->
    @nativeEditor?.focus()
    #atom.views.getView(@).focus()

  ###
  Section: Scrolling
  ###

  # Public: Scroll point {Object} with keys:
  #
  # - `x` {Number} x posisition.
  # - `y` {Number} y posisition.
  Object.defineProperty @::, 'scrollPoint',
    get: ->
      @nativeEditor.scrollPoint
    set: (scrollPoint) ->
      unless @maintainScrollPointCount
        @nativeEditor.scrollPoint = scrollPoint

  maintainScrollPoint: (callback) ->
    @_beginMaintainScrollPoint()
    callback()
    @_endMaintainScrollPoint()

  _beginMaintainScrollPoint: ->
    if @maintainScrollPointCount is 0
      scrollPoint = @scrollPoint
      characterIndex = @getCharacterIndexForPoint(0, scrollPoint.y)
      rect = @getRectForRange(characterIndex, 1)
      @maintainScrollPointData =
        scrollPoint: scrollPoint
        characterIndex: characterIndex
        characterIndexOffset: scrollPoint.y - rect.y
    @maintainScrollPointCount++

  _endMaintainScrollPoint: ->
    @maintainScrollPointCount--
    if @maintainScrollPointCount is 0
      data = @maintainScrollPointData
      rect = @getRectForRange(Math.min(data.characterIndex, @textLength), 1)
      characterIndexOffset = data.characterIndexOffset
      @maintainScrollPointData = null
      @scrollPoint =
        x: rect.x
        y: rect.y + characterIndexOffset

  # Public: Adjust {::scrollPoint} by the given delta.
  #
  # - `xDelta` {Number} scroll point x delta.
  # - `yDelta` {Number} scroll point y delta.
  scrollBy: (xDelta, yDelta) ->
    p = @scrollPoint
    p.x += xDelta
    p.y += yDelta
    @scrollPoint = p

  # Public: Scroll the given range to visible in the text buffer.
  #
  # - `location` {Number} character location.
  # - `length` {Number} character range length.
  scrollRangeToVisible: (location, length) ->
    if @maintainScrollPointCount
      return

    unless location?
      selection = @selection
      location = selection.location
      length = selection.length

    @nativeEditor.scrollRangeToVisible
      location: location
      length: length

  # Public: Get rectangle for the given character range.
  #
  # - `location` {Number} character location.
  # - `length` {Number} character range length.
  #
  # Returns {Object} with `x`, `y`, `width`, and `height` keys.
  getRectForRange:(location, length) ->
    textLength = @textLength
    location = Math.min(location, textLength)
    length = Math.min(length, textLength - location)
    @nativeEditor.getRectForRange
      location: location
      length: length

  # Public: Get character index for the given point.
  #
  # - `x` {Number} x position.
  # - `y` {Number} y position.
  #
  # Returns {Number} character index.
  getCharacterIndexForPoint: (x, y) ->
    @nativeEditor.getCharacterIndexForPoint
      x: x
      y: y

  ###
  Section: Insert
  ###

  insertNewline: (e, autoIndent=true, autoFormat=true) ->
    outline = @outline
    selection = @selection

    @maintainScrollPoint =>
      outline.groupUndo =>
        unless selection.isCollapsed
          @itemBuffer.updateOutline =>
            @itemBuffer.replaceRange(selection.location, selection.length, '')
          @moveSelectionToRange(selection.location)
          selection = @selection

        startItem = selection.startItem

        unless startItem
          @insertItem()
          return

        startItemSpan = @itemBuffer.getItemSpanForItem(startItem)
        startOffset = selection.startOffset

        if autoFormat and Birch.preferences.get('BAutoformatListsAsYouType')
          match = startItem.bodyString.match(/(^- )(.*)/)

        prefix = match?[1] ? ''
        content = match?[2] ? startItem.bodyString
        lead = prefix.length

        if startOffset <= lead and (not prefix or content)
          @insertItem('', true, autoIndent)
          @moveSelectionToItems(startItem, startOffset)
        else if startOffset is lead and (prefix and not content)
          startItem.bodyString = ''
        else
          splitText = startItem.bodyAttributedSubstringFromRange(startOffset, -1)
          startItem.replaceBodyRange(startOffset, -1, '')
          @moveSelectionToItems(startItem, -1)
          if prefix and splitText.string.indexOf(prefix) isnt 0
            splitText.insertText(0, prefix)
            insertedItem = @insertItem(splitText, false, autoIndent)
            @moveSelectionToItems(insertedItem, prefix.length)
          else
            @insertItem(splitText, false, autoIndent)
    @scrollRangeToVisible()

  insertNewlineWithoutIndent: (e) ->
    @insertNewline(e, false, false)

  insertNewlineAbove: ->
    @insertItem('', true)

  insertNewlineBelow: ->
    @insertItem('')

  insertItem: (text='', above=false, autoIndent=true) ->
    outline = @outline
    selectedItems = @selection.selectedItems
    firstSelected = selectedItems[0]
    lastSelected = selectedItems[selectedItems.length - 1]
    insertItem = outline.createItem(text)
    insetItemDepth = null

    if above
      if not firstSelected
        insertBefore = @firstDisplayedItem
      else
        insertBefore = firstSelected
    else
      if not lastSelected
        insertBefore = @glastDisplayedItem?.nextBranch
      else
        insertBefore = @getNextDisplayedItem(lastSelected)
        unless lastSelected.contains(insertBefore)
          insertBefore = lastSelected.nextBranch

    unless insertBefore
      insertBefore = lastSelected?.nextBranch ? @hoistedItem.nextBranch

    if autoIndent
      insertItem.indent = Math.max(lastSelected?.depth ? 0, insertBefore?.depth ? 0, @hoistedItem.depth + 1)
    else
      insertItem.indent = @hoistedItem.depth + 1

    @maintainScrollPoint =>
      outline.groupUndoAndChanges ->
        outline.insertItemsBefore(insertItem, insertBefore)
      @forceDisplayed(insertItem)
      @moveSelectionToItems(insertItem)

    @scrollRangeToVisible()
    @focus()

    insertItem


  # Three items to consider.
  #
  # - Level of item being moved.
  # - Item to insert after.
  # - Item to insert before.
  # - Levels of
  #
  # Generally insert after and insert before items should be visible. There
  # may be hidden items between them. Problem is to figure out where to insert
  # relative to those hidden items.
  #
  # Must not insert such that moved item captures invisible items. Because
  # then those items will "stick" to the moved item so the move is not
  # reversable.
  _getInsertBeforeItemFromInsertAfterItemAtDepth: (insertAfterItem, depth) ->
    #return @getFirstDisplayedDescendant(insertAfterItem) ? insertAfterItem.nextBranch # old way

    each = insertAfterItem?.nextItem
    while each and not @isDisplayed(each) and each.depth > depth
      each = each.nextItem
    each

  ###
  Section: Move Lines
  ###

  moveLinesUp: ->
    @_moveLinesInDirection('up')

  moveLinesDown: ->
    @_moveLinesInDirection('down')

  moveLinesLeft: ->
    @_moveLinesInDirection('left')

  moveLinesRight: ->
    @_moveLinesInDirection('right')

  _moveLinesInDirection: (direction) ->
    selection = @selection
    moveItems = selection.displayedAncestorSelectedItems
    lastMoveItem = moveItems[moveItems.length - 1]

    if moveItems.length
      outline = @outline
      undoManager = outline.undoManager
      minDepth = @hoistedItem.depth + 1
      minMovedItemDepth = Number.MAX_VALUE
      for each in moveItems
        minMovedItemDepth = Math.min(each.depth, minMovedItemDepth)
      displayedItems = (each.item for each in @itemBuffer.getSpans(0, @itemBuffer.getSpanCount()))
      items = moveItems.concat(selection.trailingHiddenDescendentItems)
      firstItem = items[0]
      lastItem = items[items.length - 1]
      dontShiftItems = new Set
      insertBeforeItem = null
      indentDelta = 0

      switch direction
        when 'up'
          unless insertBeforeItem = @getPreviousDisplayedItem(firstItem)
            return
          if insertAfterItem = @getPreviousDisplayedItem(insertBeforeItem)
            insertBeforeItem = @_getInsertBeforeItemFromInsertAfterItemAtDepth(insertAfterItem, minMovedItemDepth)

        when 'down'
          if insertAfterItem = @getNextDisplayedItem(lastItem)
            insertBeforeItem = @_getInsertBeforeItemFromInsertAfterItemAtDepth(insertAfterItem, minMovedItemDepth)
          else
            return

        when 'left'
          indentDelta = -1
          for each in items
            unless @isDisplayed(each)
              ancestor = @getDisplayedAncestor(each)
              if ancestor? and ancestor.depth is minDepth
                dontShiftItems.add(each)

        when 'right'
          indentDelta = 1

      # left or right case
      if indentDelta isnt 0
        minMovedItemDepth = Math.max(minDepth, minMovedItemDepth + indentDelta)
        insertBeforeItem = @_getInsertBeforeItemFromInsertAfterItemAtDepth(lastItem, minMovedItemDepth)

      @maintainScrollPoint =>
        selection.prepareForMove()
        @itemBuffer.ignoreItemsAddedToOutline++
        outline.groupUndoAndChanges ->
          outline.removeItems(items)
          if indentDelta
            for each in items
              unless dontShiftItems.has(each)
                each.indent = Math.max(minDepth, each.indent + indentDelta)
          outline.insertItemsBefore(items, insertBeforeItem)
        @itemBuffer.ignoreItemsAddedToOutline--
        @forceDisplayed(displayedItems)
        selection.restoreAfterMove()
        @moveSelectionToItems(selection)
      @scrollRangeToVisible()

  groupLines: ->
    selection = @selection
    items = selection.displayedAncestorSelectedItems.concat(selection.trailingHiddenDescendentItems)

    if items.length > 0
      outline = @outline
      first = items[0]
      group = outline.createItem ''
      @maintainScrollPoint =>
        outline.groupUndo =>
          first.parent.insertChildrenBefore(group, first)
          outline.removeItems(items)
          items = Item.buildItemHiearchy(items)
          @moveBranches(items, group, null, scrollRangeToVisible: false)
      @moveSelectionToItems(group)
      @scrollRangeToVisible()

  duplicateLines: ->
    selection = @selection
    items = selection.displayedAncestorSelectedItems.concat(selection.trailingHiddenDescendentItems)

    if items.length > 0
      outline = @outline
      collapsedClones = []
      clonedItems = []

      for each in items
        clonedItems.push each.clone false, (oldID, cloneID, clonedItem) =>
          oldItem = outline.getItemForID(oldID)
          if oldItem is selection.startItem
            selection.startItem = clonedItem
          if oldItem is selection.endItem
            selection.endItem = clonedItem
          if @isCollapsed(oldItem)
            collapsedClones.push(clonedItem)

      last = items[items.length - 1]
      insertBefore = last.nextItem

      @maintainScrollPoint =>
        outline.groupUndoAndChanges =>
          outline.insertItemsBefore(clonedItems, insertBefore)
          @setCollapsed(collapsedClones)
      @moveSelectionToItems(selection)
      @scrollRangeToVisible()

  deleteLines: ->
    selection = @selection
    items = selection.displayedAncestorSelectedItems.concat(selection.trailingHiddenDescendentItems)

    if items.length
      displayedItems = (each.item for each in @itemBuffer.getSpans(0, @itemBuffer.getSpanCount()))
      spanIndex = @itemBuffer.getItemSpanForItem(items[0]).getSpanIndex()
      outline = @outline

      @maintainScrollPoint =>
        outline.groupUndo =>
          outline.beginChanges()
          outline.removeItems(items)
          outline.endChanges =>
            @forceDisplayed(_.difference(displayedItems, items))

      nextSelectedItem = @itemBuffer.getSpan(spanIndex)?.item
      nextSelectedItem ?= @itemBuffer.getSpan(spanIndex - 1)?.item
      if nextSelectedItem
        @moveSelectionToItems(nextSelectedItem)
      @scrollRangeToVisible()

  ###
  Section: Move Branches
  ###

  moveBranchesUp: ->
    @_moveBranchesInDirection('up')

  moveBranchesDown: ->
    @_moveBranchesInDirection('down')

  moveBranchesLeft: ->
    @_moveBranchesInDirection('left')

  moveBranchesRight: ->
    @_moveBranchesInDirection('right')

  _moveBranchesInDirection: (direction) ->
    items = Item.getCommonAncestors(@selection.displayedAncestorSelectedItems)

    if items.length > 0
      startItem = items[0]
      newNextSibling
      newParent

      if direction is 'up'
        newNextSibling = @getPreviousDisplayedItem(startItem)
        if newNextSibling
          newParent = newNextSibling.parent
      else if direction is 'down'
        endItem = items[items.length - 1].lastBranchItem
        newPreviouseItem = @getNextDisplayedItem(endItem)
        if newPreviouseItem
          newNextSibling = @getNextDisplayedItem(newPreviouseItem)
          if newNextSibling
            newParent = newNextSibling.parent
          else
            newParent = newPreviouseItem.parent
      else if direction is 'left'
        startItemParent = startItem.parent
        if startItemParent isnt @hoistedItem
          newParent = startItemParent.parent
          newNextSibling = @getNextDisplayedSibling(startItemParent)
          while newNextSibling and newNextSibling in items
            newNextSibling = @getNextDisplayedSibling(newNextSibling)
      else if direction is 'right'
        newParent = @getPreviousDisplayedSibling(startItem)

      if newParent
        @moveBranches(items, newParent, newNextSibling)

  groupBranches: ->
    items = Item.getCommonAncestors(@selection.displayedAncestorSelectedItems)
    if items.length > 0
      outline = @outline
      first = items[0]
      outline.groupUndo =>
        group = outline.createItem ''
        @maintainScrollPoint =>
          first.parent.insertChildrenBefore(group, first)
          @moveBranches(items, group)
        @moveSelectionToItems(group)
      @scrollRangeToVisible()

  duplicateBranches: ->
    selection = @selection
    items = Item.getCommonAncestors(selection.displayedAncestorSelectedItems)

    if items.length > 0
      outline = @outline
      expandedClones = []
      clonedItems = []

      for each in items
        clonedItems.push each.clone true, (oldID, cloneID, clonedItem) =>
          oldItem = outline.getItemForID(oldID)
          if oldItem is selection.startItem
            selection.startItem = clonedItem
          if oldItem is selection.endItem
            selection.endItem = clonedItem
          if @isExpanded(oldItem)
            expandedClones.push(clonedItem)

      last = items[items.length - 1]
      insertBefore = last.nextSibling
      parent = insertBefore?.parent ? items[0].parent

      @maintainScrollPoint =>
        @setExpanded(expandedClones)
        parent.insertChildrenBefore(clonedItems, insertBefore)
      @moveSelectionToItems(selection)
      @scrollRangeToVisible()

  promoteChildBranches: ->
    item = @selection.startItem
    if item
      @moveBranches(item.children, item.parent, item.nextSibling)
      @outline.undoManager.setActionName('Promote Children')

  demoteTrailingSiblingBranches: ->
    item = @selection.startItem
    if item
      trailingSiblings = []

      each = item.nextSibling
      while each
        trailingSiblings.push(each)
        each = each.nextSibling

      if trailingSiblings.length > 0
        @moveBranches(trailingSiblings, item, null)
        @outline.undoManager.setActionName('Demote Siblings')

  moveBranchesToParent: (items, newParent) ->
    selectedCommonAncestors = Item.getCommonAncestors(items ? @selection.displayedAncestorSelectedItems)
    for each in selectedCommonAncestors
      if each is newParent or each.contains(newParent)
        return

    selectedItems = @selection.selectedItems
    nextSelection = @getPreviousDisplayedItem(selectedItems[0])
    unless nextSelection
      nextSelection = @getNextDisplayedItem(selectedItems[selectedItems.length - 1])
    @maintainScrollPoint ->
      newParent.insertChildrenBefore(selectedCommonAncestors, newParent.firstChild)
    if nextSelection
      @moveSelectionToItems(nextSelection)
    @scrollRangeToVisible()

  moveBranches: (items, newParent, newNextSibling, options={}) ->
    options.moveSelectionWithItems ?= true
    options.scrollRangeToVisible ?= true

    items = Item.getCommonAncestors(items ? @selection.displayedAncestorSelectedItems)
    for each in items
      if each is newParent or each.contains(newParent)
        return

    if items.length is 0
      return

    if items[0] is newNextSibling
      return

    outline = @outline
    selection = @selection
    itemsOutline = items[0].outline

    assert(newParent.outline is outline, 'newParent must be in editor outline')
    assert(not newNextSibling or newNextSibling.outline is outline, 'newNextSibling must be in editor outline')

    for each in items
      assert(each.outline is itemsOutline, 'items must all be part of same outline')

    if outline isnt itemsOutline
      itemsOutline.groupUndoAndChanges ->
        Item.removeItemsFromParents(items)
      importedItems = []
      for each in items
        importedItems.push(outline.importItem(each))
      items = importedItems

    # If new parent is displayed then make sure that all visible moved items
    # are also displayed after the move.
    forceDisplayItems = []
    if @isDisplayed(newParent)
      for each in items
        if @isDisplayed(each)
          forceDisplayItems.push(each)
        for each in each.descendants
          if @isDisplayed(each)
            forceDisplayItems.push(each)

    # If don't want to move selection with moved branches then first determine
    # if selection is part of moved branches and if so move selection before
    # first branch, or after last branch.
    unless options.moveSelectionWithItems
      moveSelectionAwayFromItems = false
      if startItem = selection.startItem
        for each in items
          if each is startItem or each.contains(startItem)
            moveSelectionAwayFromItems = true
      if endItem = selection.endItem
        for each in items
          if each is endItem or each.contains(endItem)
            moveSelectionAwayFromItems = true
      if moveSelectionAwayFromItems
        if newStartItem = @getNextDisplayedItem(items[items.length - 1].lastBranchItem) ? @getPreviousDisplayedItem(items[0])
          selection = startItem: newStartItem
        else
          selection = start: 0

    selection.prepareForMove?()

    @maintainScrollPoint =>
      # Shouldn't manaully expand parents here... instead should get visible items of the moved branches
      # Make the outline change. Then manually make appropriate items visible in the buffer.
      outline.groupUndoAndChanges ->
        Item.removeItemsFromParents(items)
        newParent.insertChildrenBefore items, newNextSibling
      @forceDisplayed(forceDisplayItems)

    selection.restoreAfterMove?()
    @moveSelectionToItems(selection)

    if options.scrollRangeToVisible
      @scrollRangeToVisible()

  deleteBranches: (items) ->
    items = Item.getCommonAncestors(items ? @selection.displayedAncestorSelectedItems)
    if items.length
      spanIndex = @itemBuffer.getItemSpanForItem(items[0]).getSpanIndex()
      @maintainScrollPoint =>
        @outline.groupUndoAndChanges ->
          Item.removeItemsFromParents(items)
      nextSelection = @itemBuffer.getSpan(spanIndex)?.item
      nextSelection ?= @itemBuffer.getSpan(spanIndex - 1)?.item
      if nextSelection
        @moveSelectionToItems(nextSelection)
      @scrollRangeToVisible()

  ###
  Section: Formatting
  ###

  Object.defineProperty @::, 'typingAttributes',
    get: ->
      unless @_typingAttributes
        selection = @selection
        startItem = selection.startItem
        formattingOffset = selection.startOffset
        unless selection.isCollapsed
          formattingOffset += 1
        if formattingOffset > 0
          @_typingAttributes = startItem.getBodyAttributesAtIndex(formattingOffset - 1)
        else
          @_typingAttributes = startItem.getBodyAttributesAtIndex(formattingOffset)
      @_typingAttributes
    set: (typingAttributes) ->
      if typingAttributes?
        @_typingAttributes = Object.assign({}, typingAttributes)
      else
        @_typingAttributes = null

  toggleTypingAttribute: (name, value) ->
    typingAttributes = @typingAttributes
    if typingAttributes[name] isnt undefined
      delete typingAttributes[name]
    else
      typingAttributes[name] = value or null
    @typingAttributes = typingAttributes

  toggleTextAttribute: (name, attributes={}) ->
    startItem = @selection.startItem
    selection = @selection
    if selection.length is 0
      @toggleTypingAttribute(name, attributes)
    else if startItem
      tagAttributes = startItem.getBodyAttributeAtIndex(name, selection.startOffset or 0)
      addingTag = tagAttributes is undefined
      @_transformSelectedText (eachItem, start, end) ->
        if (addingTag)
          eachItem.addBodyAttributeInRange(name, attributes, start, end - start)
        else
          eachItem.removeBodyAttributeInRange(name, start, end - start)

  clearFormatting: ->
    selection = @selection
    if selection.length is 0
      longestRange = {}
      startItem = selection.startItem
      startOffset = selection.startOffset
      startTextLength = startItem.bodyString.length

      if startTextLength is 0
        return

      if startOffset is startTextLength
        startOffset--

      attributes = startItem.getBodyAttributesAtIndex(startOffset, null, longestRange)
      unless Object.keys(attributes).length
        return

      @moveSelectionToItems(startItem, longestRange.location, startItem, longestRange.end)

    @_transformSelectedText (eachItem, start, end) ->
      attributedString = new AttributedString(eachItem.bodyString.substring(start, end))
      eachItem.replaceBodyRange(start, end - start, attributedString)

  upperCase: ->
    @_transformSelectedText (item, start, end) ->
      item.replaceBodyRange(start, end - start, item.bodyString.substring(start, end).toUpperCase())

  lowerCase: ->
    @_transformSelectedText (item, start, end) ->
      item.replaceBodyRange(start, end - start, item.bodyString.substring(start, end).toLowerCase())

  _transformSelectedText: (transform) ->
    if @selection.isCollapsed
      @selectWord()

    selection = @selection
    outline = @outline

    @maintainScrollPoint ->
      outline.groupUndoAndChanges ->
        startItem = selection.startItem
        startOffset = selection.startOffset
        endItem = selection.endItem
        endOffset = selection.endOffset

        for each in selection.displayedAncestorSelectedItems
          if each is startItem and each is endItem
            transform(each, startOffset, endOffset)
          else if each is startItem
            transform(each, startOffset, each.bodyString.length)
          else if each is endItem
            transform(each, 0, endOffset)
          else
            transform(each, 0, each.bodyString.length)

    @moveSelectionToItems(selection)

  insertDate: (completedCallback) ->
    @getDateFromUser 'Insert Date', '%@', (date) =>
      if date
        @insertText(DateTime.format(date, false, false))
        completedCallback?(true)
      else
        completedCallback?(false)

  ###
  Section: Util
  ###

  getItemAttributesFromUser: (placeholder, callback) ->
    @nativeEditor.getItemAttributesFromUserCallback(placeholder, callback)

  getDateFromUser: (placeholder, stringTemplate, callback) ->
    @nativeEditor.getDateFromUserDateStringTemplateCallback(placeholder, stringTemplate, callback)

  setAttribute: (items, name, value, scrollRangeToVisible=true) ->
    attributes = {}
    attributes[name] = value
    @setAllAttributes(items, attributes, scrollRangeToVisible)

  setAllAttributes: (items, attributes, scrollRangeToVisible=true) ->
    outline = @outline
    selection = @selection
    items ?= selection.displayedSelectedItems
    @maintainScrollPoint ->
      outline.groupUndoAndChanges ->
        attributeNames = Object.keys(attributes)
        for each in items
          for eachName in attributeNames
            each.setAttribute(eachName, attributes[eachName])
    @moveSelectionToItems(selection)

    if scrollRangeToVisible
      @scrollRangeToVisible()

  hasAttribute: (name, items) ->
    @hasAllAttributes([name], items)

  hasAllAttributes: (attributes, items) ->
    items ?= @selection.displayedSelectedItems
    if items
      for eachItem in items
        for eachAttribute in attributes
          unless eachItem.hasAttribute(eachAttribute)
            return false
      true
    else
      false

  toggleAttribute: (name, value='', items, scrollRangeToVisible=true) ->
    items ?= @selection.displayedSelectedItems
    if @hasAttribute(name, items)
      value = null
    @setAttribute(items, name, value, scrollRangeToVisible)

  toggleUserSelectedAttribute: (items, scrollRangeToVisible=true, completedCallback) ->
    items ?= @selection.displayedSelectedItems
    @getItemAttributesFromUser 'Tag With', (attributeNames) =>
      if attributeNames
        if @hasAllAttributes(attributeNames, items)
          attributes = {}
          for each in attributeNames
            attributes[each] = null
          @setAllAttributes(items, attributes, scrollRangeToVisible)
          completedCallback?(true)
        else
          outline = @outline
          outline.beginUndoGrouping()
          oldCompletedCallback = completedCallback
          newCompletedCallback = (result) ->
            outline.endUndoGrouping()
            oldCompletedCallback?(result)
          directSetAttributes = []
          commandSetAttributes = []
          for each in attributeNames
            commandName = "outline-editor:toggle-#{each.substring(5)}" # trim `data-` from front
            if Birch.commands.hasCommand(@, commandName)
              commandSetAttributes.push
                name: commandName
            else
              directSetAttributes.push(each)
          if directSetAttributes.length > 0
            attributes = {}
            for each in directSetAttributes
              attributes[each] = ''
            @setAllAttributes(items, attributes, scrollRangeToVisible)
          if commandSetAttributes.length > 0
            @performCommands(commandSetAttributes, newCompletedCallback)
          else
            newCompletedCallback(true)
      else
        completedCallback?(false)

  ###
  Section: Item Serialization
  ###

  # Public: Get item serialization from the given range.
  #
  # - `location` {Number} character location.
  # - `length` {Number} character range length.
  # - `options` Serialization options as defined in {ItemSerializer}.
  serializeRange: (location, length, options={}) ->
    @itemBuffer.serializeRange(location, length, options)

  serializeItems: (items, options={}) ->
    @itemBuffer.serializeItems(items, options)

  deserializeItems: (serializedItems, options={}) ->
    @itemBuffer.deserializeItems(serializedItems, options)

  getSerializedItemsInRange: OutlineEditor::serializeRange # Backward compatibilty API

  ###
  Section: Editor State Serialization
  ###

  invalidateRestorableState: ->
    @nativeEditor?.invalidateRestorableState()

  Object.defineProperty @::, 'restorableState',
    get: ->
      collapsedItems = []
      each = @outline.root.firstChild
      while each
        if @isExplicitlyCollapsed(each)
          collapsedItems.push(each)
        each = each.nextItem

      {} =
        hoistedItem: @hoistedItem
        focusedItem: @focusedItem
        itemPathFilter: @itemPathFilter
        collapsedItems: collapsedItems
        displayedItems: @displayedItems

    set: (state) ->
      @maintainScrollPoint =>
        if state.collapsedItems
          @itemBuffer.updateIndex =>
            @setCollapsed(state.collapsedItems)
        @editorState =
          hoistedItem: state.hoistedItem ? @outline.root
          focusedItem: state.focusedItem
          itemPathFilter: state.itemPathFilter ? ''
          displayedItems: state.displayedItems

  Object.defineProperty @::, 'serializedRestorableState',
    get: ->
      collapsedItemIDs = []
      each = @outline.root.firstChild
      while each
        if @isExplicitlyCollapsed(each)
          collapsedItemIDs.push(each.branchContentID)
        each = each.nextItem

      state =
        hoistedID: @hoistedItem.branchContentID
        focusedID: @focusedItem?.branchContentID
        collapsedItemIDs: collapsedItemIDs
        itemPathFilter: @itemPathFilter

      JSON.stringify(state)

    set: (jsonState) ->
      if @_reloadingSerializedRestorableState
        return

      if state = JSON.parse(jsonState)
        outline = @outline

        collapsedItems = []
        if collapsedItemIDs = state.collapsedItemIDs
          for eachID in collapsedItemIDs
            if eachItem = outline.getItemForBranchContentID(eachID)
              collapsedItems.push(eachItem)

        @restorableState =
          hoistedItem: outline.getItemForBranchContentID(state.hoistedID)
          focusedItem: outline.getItemForBranchContentID(state.focusedID)
          collapsedItems: collapsedItems
          itemPathFilter: state.itemPathFilter

  _outlineWillReload: ->
    @_reloadingSerializedRestorableState = @serializedRestorableState

  _outlineDidReload: ->
    state = @_reloadingSerializedRestorableState
    @_reloadingSerializedRestorableState = null
    @serializedRestorableState = state

  ###
  Section: Scripting
  ###

  evaluateScript: (script, options) ->
    result = '_wrappedValue': null
    try
      if options
        options = JSON.parse(options)._wrappedValue
      func = eval("(#{script})")
      API_VERSION = major: 0, minor: 9, patch: 0
      r = func(this, options)
      if r is undefined
        r = null # survive JSON round trip
      result._wrappedValue = r
    catch e
      result._wrappedValue = "#{e.toString()}\n\n#{e.stack}\n\n\tUse the Help > SDKRunner to debug"
    JSON.stringify(result)

  ###
  Section: Commands
  ###

  performCommand: (commandName, details, completedCallback) ->
    Birch.commands.dispatch(@, commandName, details, completedCallback)

  performCommands: (commands, completedCallback) ->
    next = commands.shift()
    if next
      @performCommand next.name, next.details, =>
        @performCommands(commands, completedCallback)
    else
      completedCallback?()

  validateCommandMenuItem: (commandName, menuItem) ->
    switch commandName
      when 'outline-editor:undo'
        @outline.undoManager.canUndo()
      when 'outline-editor:redo'
        @outline.undoManager.canRedo()

  insertTab: (e) ->
    selection = @selection
    @replaceRangeWithString(selection.location, selection.length, '\t')

  insertBacktab: (e) ->

  backspace: (e) ->
    selection = @selection
    deleteRange = location: selection.location, length: selection.length
    if deleteRange.length is 0 and deleteRange.location > 0
      deleteRange.location--
      deleteRange.length = 1
    @replaceRangeWithString(deleteRange.location, deleteRange.length, '')

  undo: ->
    @outline.undoManager.undo()

  redo: ->
    @outline.undoManager.redo()

  ###
  Section: Delegate
  ###

  clickedOnItemLink: (item, link) ->
    if link is 'button://toggledone'
      if Birch.preferences.get('BIncludeDateWhenTaggingDone')
        value = moment().format('YYYY-MM-DD')
      @toggleAttribute('data-done', value, [item], false)
      true
    else if link.indexOf('filter://') is 0
      @itemPathFilter = link.substring(9)
      true
    else
      false

  ###
  Section: Guides and Gaps (Helpers for Drawing)
  ###

  getGuideRangesForVisibleRange: (location, length) ->
    itemSpansInRange = @itemBuffer.getSpansInRange(location, length, true)
    hoistedItem = @hoistedItem
    ancestors = new Set()
    ancestors.add(hoistedItem)
    guideRanges = []

    for eachSpan in itemSpansInRange
      item = eachSpan.item
      ancestor = item
      while not ancestors.has(ancestor)
        ancestorSpan = @itemBuffer.getItemSpanForItem(ancestor)
        lastDisplayedSpan = @itemBuffer.getItemSpanForItem(@getLastDisplayedDescendantOrSelf(ancestor))
        if ancestorSpan and ancestorSpan isnt lastDisplayedSpan
          location = ancestorSpan.getLocation()
          end = lastDisplayedSpan.getEnd()
          guideRanges.push(location)
          guideRanges.push(end - location)
        ancestors.add(ancestor)
        ancestor = ancestor.parent
    guideRanges

  getGapLocationsForVisibleRange: (location, length) ->
    itemSpansInRange = @itemBuffer.getSpansInRange(location, length, true)
    selection = @selection
    selectedItems = selection.selectedItems
    selectionStart = selection.start
    selectionEnd = selection.end
    gapLocations = []

    for eachSpan, index in itemSpansInRange
      eachItem = eachSpan.item
      nextItemInBuffer = itemSpansInRange[index + 1]?.item
      if nextItemInBuffer or eachItem.firstChild
        if (nextItem = eachItem.nextItem) and (nextItem isnt nextItemInBuffer)
          # Now we know there is a gap. Next question... is that gap ever
          # selectable. And if it is selectable at what indentation level
          # should the gap be drawn?
          if @getDisplayedAncestor(nextItem)?
            eachGapItem = eachItem.nextItem
            gapItemLocation = eachSpan.getLocation()
            gapItemEnd = gapItemLocation + eachItem.bodyString.length
            gapSelected = 0

            if gapItemEnd >= selectionStart and gapItemEnd < selectionEnd
              if selectedItems.includes(nextItem)
                gapSelected = 1
            gapLocations.push(gapItemLocation, gapSelected)

    gapLocations

module.exports = OutlineEditor
