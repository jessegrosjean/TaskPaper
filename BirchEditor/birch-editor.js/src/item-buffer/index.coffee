{ Outline, Item, Mutation, ItemSerializer, util }  = require 'birch-outline'
{ CompositeDisposable } = require 'event-kit'
LineBuffer = require '../line-buffer'
Selection = require '../selection'
ItemSpan = require './item-span'
Birch = require '../birch'
assert = util.assert

class ItemBuffer extends LineBuffer

  constructor: (@outline, @editor) ->
    super()
    @isUpdatingIndex = 0
    @isUpdatingOutline = 0
    @ignoreItemsAddedToOutline = 0

    @_bufferState = {}
    @_collapsedItems = new Set
    @_itemsToExpansionStateCache = new Map
    @_invalidateItemCalculatedStyles = null

    @subscriptions = new CompositeDisposable
    @subscriptions.add @outline.onDidBeginChanges @_outlineDidBeginChanges.bind(this)
    @subscriptions.add @outline.onDidChange @_outlineDidChange.bind(this)
    @subscriptions.add @outline.onDidEndChanges @_outlineDidEndChanges.bind(this)
    @subscriptions.add @outline.onDidDestroy => @destroy()

    @outline.retain()

  destroy: ->
    unless @destroyed
      @subscriptions.dispose()
      super()
      @outline.release()

  ###
  Section: Changes
  ###

  beginChanges: (changeEvent) ->
    unless @isUpdatingIndex or @isUpdatingOutline
      throw new Error('Must first call @beginUpdatingIndex or @beginUpdatingOutline before making changes to item buffer')
    if @changing is 0
      @_invalidateItemCalculatedStyles = new Set
    super(changeEvent)

  endChanges: ->
    unless @isUpdatingIndex or @isUpdatingOutline
      throw new Error('Must first call @beginUpdatingIndex or @beginUpdatingOutline before making changes to item buffer')
    if @changing is 1
      @_invalidateItemCalculatedStyles.forEach (each) =>
        @_itemsToExpansionStateCache.delete(each)
        @editor?.invalidateItem(each, null)

    super()

  beginUpdatingIndex: ->
    if @isUpdatingOutline
      throw new Error('Can not update index at same time as outline')
    @isUpdatingIndex++
    @beginChanges()

  endUpdatingIndex: ->
    @endChanges()
    @isUpdatingIndex--
    if @isUpdatingIndex is 0
      @_validateBufferState()

  updateIndex: (callback) ->
    @beginUpdatingIndex()
    callback()
    @endUpdatingIndex()

  beginUpdatingOutline: ->
    if @isUpdatingIndex
      throw new Error('Can not update outline at same time as index')
    @isUpdatingOutline++
    @outline.beginChanges()
    @beginChanges()

  endUpdatingOutline: ->
    @endChanges()
    unless @hoistedItem.isInOutline
      @hoistedItem = @outline.root
    @outline.endChanges()
    @isUpdatingOutline--
    if @isUpdatingOutline is 0
      @_validateBufferState()

  updateOutline: (callback) ->
    @beginUpdatingOutline()
    callback()
    @endUpdatingOutline()

  _validateBufferState: ->
    unless @hoistedItem.isInOutline
      @hoistedItem = @outline.root
    if focusedItem = @focusedItem
      unless @focusedItem.parent is @hoistedItem
        @_bufferState.focusedItem = null
        @emitter.emit 'did-change-focused-item', @focusedItem

  ###
  Section: Events
  ###

  onWillProcessOutlineMutation: (callback) ->
    @_getEmitter().on 'will-process-outline-mutation', callback

  onDidProcessOutlineMutation: (callback) ->
    @_getEmitter().on 'did-process-outline-mutation', callback

  onDidChangeHoistedItem: (callback) ->
    @_getEmitter().on 'did-change-hoisted-item', callback

  onDidChangeFocusedItem: (callback) ->
    @_getEmitter().on 'did-change-focused-item', callback

  onDidChangeItemPathFilter: (callback) ->
    @_getEmitter().on 'did-change-item-path-filter', callback

  ###
  Section: Buffer State
  ###

  Object.defineProperty @::, 'hoistedItem',
    get: -> @bufferState.hoistedItem
    set: (hoistedItem) -> @bufferState = hoistedItem: hoistedItem

  Object.defineProperty @::, 'focusedItem',
    get: -> @bufferState.focusedItem
    set: (focusedItem) -> @bufferState = focusedItem: focusedItem

  Object.defineProperty @::, 'itemPathFilter',
    get: -> @bufferState.itemPathFilter
    set: (itemPathFilter) -> @bufferState = itemPathFilter: itemPathFilter

  Object.defineProperty @::, 'bufferState',
    get: -> @_bufferState
    set: (bufferState) ->
      outline = @outline

      prevHoistedItem = @hoistedItem
      prevFocusedItem = @focusedItem
      prevItemPathFilter = @itemPathFilter

      #if bufferState.focusedItem is null or bufferState.hoistedItem is null
      #  bufferState.hoistedItem = outline.root
      #  bufferState.focusedItem = null

      if bufferState.focusedItem
        if bufferState.focusedItem.isOutlineRoot
          bufferState.hoistedItem = bufferState.focusedItem
          bufferState.focusedItem = null
        else
          bufferState.hoistedItem = bufferState.focusedItem.parent

      if bufferState.hoistedItem
        if Birch.preferences.get('BMaintainItemPathFilterWhenHoisting')
          bufferState.itemPathFilter ?= prevItemPathFilter
      else
        if Birch.preferences.get('BMaintainHoistedItemWhenFiltering')
          bufferState.hoistedItem = prevHoistedItem ? outline.root
          bufferState.focusedItem = prevFocusedItem
        else
          bufferState.hoistedItem = outline.root
          bufferState.focusedItem = null

      assert(bufferState.hoistedItem.outline is @outline)
      assert(bufferState.hoistedItem.isInOutline)
      if bufferState.focusedItem
        assert(bufferState.focusedItem.isInOutline)
        assert(bufferState.focusedItem.parent is bufferState.hoistedItem)

      bufferState.hoistedItem ?= null
      bufferState.focusedItem ?= null
      bufferState.itemPathFilter ?= ''

      displayedItems = bufferState.displayedItems
      delete bufferState.displayedItems

      @_bufferState = bufferState
      @_itemsToItemSpansMap = new Map

      @updateIndex =>
        @removeSpans(0, @getSpanCount())

        if displayedItems
          @insertSpans(0, (@createSpanForItem(each) for each in displayedItems))
        else
          @insertSpans(0, (@createSpanForItem(each) for each in @_buildBufferItemsList()))

        if @emitter
          if @hoistedItem isnt prevHoistedItem
            @emitter.emit 'did-change-hoisted-item', @hoistedItem
          if @focusedItem isnt prevFocusedItem
            @emitter.emit 'did-change-focused-item', @focusedItem
          if @itemPathFilter isnt prevItemPathFilter
            @emitter.emit 'did-change-item-path-filter', @itemPathFilter

      @editor?.invalidateRestorableState()

  _buildBufferItemsList: ->
    itemsList = []

    if @focusedItem
      localRoot = @focusedItem
      itemsList.push(@focusedItem)
    else
      localRoot = @hoistedItem

    if @itemPathFilter
      for each in @_buildMatchedItemsList(localRoot)
        itemsList.push(each)
    else
      for each in @_buildExpandedItemsList(localRoot)
        itemsList.push(each)
    itemsList

  _buildMatchedItemsList: (item) ->
    matchedList = []
    matchedSet = new Set
    outline = item.outline
    for each in outline.evaluateItemPath(@itemPathFilter, item, root: item)
      if each isnt item and item.contains(each)
        ancestor = each.parent
        ancestorInsertIndex = matchedList.length
        while ancestor isnt item
          if matchedSet.has(ancestor)
            break
          else
            matchedList.splice(ancestorInsertIndex, 0, ancestor)
            matchedSet.add(ancestor)
          ancestor = ancestor.parent
        matchedList.push(each)
        matchedSet.add(each)
    matchedList

  _buildExpandedItemsList: (item) ->
    expandedList = []
    each = item.firstChild
    end = item.nextBranch
    while each and each isnt end
      expandedList.push(each)
      if each is @focusedItem or not @_collapsedItems.has(each)
        each = each.nextItem
      else
        each = each.nextBranch
    expandedList

  _outlineDidBeginChanges: (mutation) ->
    if @isUpdatingOutline
      return
    @beginUpdatingIndex()

  _outlineDidChange: (mutation) ->
    if @isUpdatingOutline
      @_invalidateItemCalculatedStyles.add(mutation.target)
      return

    @emitter?.emit 'will-process-outline-mutation', mutation
    @updateIndex =>
      target = mutation.target
      switch mutation.type
        when Mutation.BODY_CHANGED
          if itemSpan = @getItemSpanForItem(target)
            localLocation = mutation.insertedTextLocation
            insertedString = target.bodyString.substr(localLocation, mutation.insertedTextLength)
            location = itemSpan.getLocation() + localLocation
            @replaceRange(location, mutation.replacedText.length, insertedString)

        when Mutation.CHILDREN_CHANGED
          if mutation.removedItems.length
            @_outlineDidRemoveItems(target, mutation.getFlattendedRemovedItems())
          if mutation.addedItems.length
            @_outlineDidAddItems(target, mutation.addedItems)
      @_invalidateItemCalculatedStyles.add(mutation.target)
    @emitter?.emit 'did-process-outline-mutation', mutation

  _outlineDidRemoveItems: (target, removedDescendants) ->
    removeStartIndex = undefined
    removeCount = 0

    removeRangeIfDefined = =>
      @removeLines(removeStartIndex, removeCount)
      removeStartIndex = undefined
      removeCount = 0

    for each in removedDescendants
      if itemSpan = @getItemSpanForItem(each)
        removeStartIndex ?= itemSpan.getSpanIndex()
        removeCount++
      else if removeStartIndex
        removeRangeIfDefined()
    removeRangeIfDefined()

  _outlineDidAddItems: (target, addedChildren) ->
    # Figure out of an item added in the outline should also get added to the
    # visible buffer. Also update visible buffer styles.
    if @ignoreItemsAddedToOutline
      return

    firstAdded = addedChildren[0]
    insertAfter = firstAdded.previousSibling
    lastAdded = addedChildren[addedChildren.length - 1]
    insertBefore = lastAdded.nextSibling
    pass = false

    if @isDisplayed(insertAfter)
      pass = true
    else if @isDisplayed(insertBefore)
      pass = true
    else
      if target is @hoistedItem or @isDisplayed(target)
        if not @_collapsedItems.has(target) and target.firstChild is firstAdded and target.lastChild is lastAdded
          pass = true

    return unless pass

    addedItemSpans = []
    for each in addedChildren
      addedItemSpans.push(@createSpanForItem(each))
      if @isExpanded(each)
        for each in @_buildExpandedItemsList(each)
          addedItemSpans.push(@createSpanForItem(each))

    if addedItemSpans.length
      insertBeforeItem = addedItemSpans[addedItemSpans.length - 1].item.nextItem
      while insertBeforeItem and not (insertBeforeLine = @getItemSpanForItem(insertBeforeItem))
        insertBeforeItem = insertBeforeItem.nextItem
      if insertBeforeLine
        insertIndex = insertBeforeLine.getSpanIndex()
      else
        insertAfterItem = addedItemSpans[0].item.previousItem
        while insertAfterItem and not (insertAfterLine = @getItemSpanForItem(insertAfterItem))
          insertAfterItem = insertAfterItem.nextItem
        if insertAfterLine
          insertIndex = insertAfterLine.getSpanIndex() + 1
        else
          insertIndex = @getLineCount()
      @insertSpans(insertIndex, addedItemSpans)

  _outlineDidEndChanges: (mutation) ->
    if @isUpdatingOutline
      return
    @endUpdatingIndex()

  ###
  Section: Buffer Expansion State
  ###

  isExpanded: (item) ->
    @getItemExpandedState(item) is 'expanded'

  isFiltered: (item) ->
    @getItemExpandedState(item) is 'filtered'

  isCollapsed: (item) ->
    @getItemExpandedState(item) is 'collapsed'

  isExplicitlyCollapsed: (item) ->
    @_collapsedItems.has(item)

  getItemExpandedState: (item) ->
    return unless item
    if state = @_itemsToExpansionStateCache.get(item)
      state
    else if item?.hasChildren
      if @isDisplayed(item)
        childrenShowing = false
        childrenHiding = false
        each = item.firstChild
        while each and not (childrenShowing and childrenHiding)
          if @isDisplayed(each)
            childrenShowing = true
          else
            childrenHiding = true
          each = each.nextSibling
        if childrenHiding
          if childrenShowing
            state = 'filtered'
          else
            state = 'collapsed'
        else
          state = 'expanded'
      else
        if @_collapsedItems.has(item)
          state = 'collapsed'
        else
          state = 'expanded'
    else
      state = 'leaf'

    @_itemsToExpansionStateCache.set(item, state)

    state

  setExpandedState: (items, state, completely=false) ->
    @updateIndex =>
      parents = (each for each in items when each.hasChildren)
      parents.sort (a,b) ->
        a.depth < b.depth

      for each in parents
        branchDisplayState = @getItemExpandedState(each)
        if branchDisplayState is 'filtered' or (state and branchDisplayState is 'collapsed') or (not state and branchDisplayState is 'expanded')
          @_invalidateItemCalculatedStyles.add(each)
          if state
            @_collapsedItems.delete(each)
            @_insertNeededDescendantLines(each)
          else
            @_collapsedItems.add(each)
            @_removeDescendantLines(each)

      if state
        # If expanding make sure to remove any leaf children.
        for each in items
          unless each.hasChildren
            @_collapsedItems.delete(each)

    @editor?.invalidateRestorableState()

  _insertNeededDescendantLines: (item) ->
    @_removeDescendantLines(item)
    if itemSpan = @getItemSpanForItem(item)
      @insertLines(itemSpan.getSpanIndex() + 1, (@createSpanForItem(each) for each in @_buildExpandedItemsList(item)))

  _removeDescendantLines: (item) ->
    if itemSpan = @getItemSpanForItem(item)
      startIndex = itemSpan.getSpanIndex() + 1
      endIndex = startIndex
      each = item.firstChild
      end = item.nextBranch
      while each isnt end
        if @isDisplayed(each)
          endIndex++
        each = each.nextItem
      @removeLines(startIndex, endIndex - startIndex)

  ###
  Section: Buffer Display State
  ###

  isDisplayed: (item) ->
    not not @getItemSpanForItem(item)

  forceDisplayed: (items, showAncestors=false) ->
    unless Array.isArray(items)
      items = [items]

    @updateIndex =>
      for item in items
        assert(item.isInOutline, 'force displayed item must be in outline.')
        assert(@hoistedItem.contains(item), 'force displayed item must descend from hoisted item.')

        eachAncestor = item
        while eachAncestor isnt @hoistedItem and not @isDisplayed(eachAncestor)
          each = eachAncestor.previousItem
          while each and each isnt @hoistedItem
            if eachItemSpan = @getItemSpanForItem(each)
              @insertLines(eachItemSpan.getSpanIndex() + 1, [@createSpanForItem(eachAncestor)])
              break
            each = each.previousItem
          if not each or each is @hoistedItem
            @insertLines(0, [@createSpanForItem(eachAncestor)])

          if showAncestors
            eachAncestor = eachAncestor.parent
          else
            eachAncestor = @hoistedItem # end loop

  forceHidden: (items, hideDescendants=false) ->
    unless Array.isArray(items)
      items = [items]

    @updateIndex =>
      for each in items
        if eachItemSpan = @getItemSpanForItem(each)
          @removeLines(eachItemSpan.getSpanIndex(), 1)

  Object.defineProperty @::, 'displayedItems',
    get: ->
      items = []
      @iterateLines 0, @getLineCount(), (each) ->
        items.push(each.item)
      items

  Object.defineProperty @::, 'firstDisplayedItem',
    get: -> @getNextDisplayedItem(@hoistedItem)

  Object.defineProperty @::, 'lastDisplayedItem',
    get: ->
      last = @hoistedItem.lastBranchItem
      if @isDisplayed(last)
        last
      else
        @getPreviousDisplayedItem(last)

  getDisplayedAncestor: (item) ->
    return null unless item
    ancestor = item.parent
    while ancestor
      if @isDisplayed ancestor
        return ancestor
      ancestor = ancestor.parent

  getDisplayedSelfOrAncestor: (item) ->
    return null unless item
    if @isDisplayed(item)
      return item
    @getDisplayedAncestor(item)

  getPreviousDisplayedSibling: (item) ->
    return null unless item
    item = item.previousSibling
    while item
      if @isDisplayed item
        return item
      item = item.previousSibling

  getNextDisplayedSibling: (item) ->
    return null unless item
    item = item.nextSibling
    while item
      if @isDisplayed item
        return item
      item = item.nextSibling

  getNextDisplayedItem: (item) ->
    return null unless item
    item = item.nextItem
    while item
      if @isDisplayed item
        return item
      item = item.nextItem

  getPreviousDisplayedItem: (item) ->
    return null unless item
    item = item.previousItem
    while item
      if @isDisplayed item
        return item
      item = item.previousItem

  getFirstDisplayedDescendant: (item) ->
    return null unless item
    end = item.nextBranch
    each = item.nextItem
    while each isnt end
      if @isDisplayed(each)
        return each
      each = each.nextItem

  getLastDisplayedDescendant: (item) ->
    return null unless item
    each = item.lastBranchItem
    while each isnt item
      if @isDisplayed(each)
        return each
      each = each.previousItem

  getFirstDisplayedDescendantOrSelf: (item) ->
    @getFirstDisplayedDescendant(item) ? item

  getLastDisplayedDescendantOrSelf: (item) ->
    @getLastDisplayedDescendant(item) ? item

  getDisplayedBodyCharacterRange: (item) ->
    if typeof item is 'string'
      item = @outline.getItemForID(item)

    itemSpan = @getItemSpanForItem(item)
    if itemSpan
      {} =
        location: itemSpan.getLocation()
        length: itemSpan.getLength() - 1 # trim trailing \n
    else
      null

  getDisplayedBranchCharacterRange: (item) ->
    if typeof item is 'string'
      item = @outline.getItemForID(item)

    startItemSpan = @getItemSpanForItem(item)
    if startItemSpan
      endItemSpan = @getItemSpanForItem(@getLastDisplayedDescendantOrSelf(item))
      start = startItemSpan.getLocation()
      end = endItemSpan.getLocation() + endItemSpan.getLength()
      {} =
        location: start
        length: end - start
    else
      null

  ###
  Section: Characters
  ###

  getItemOffsetForLocation:(location) ->
    length = @getLength()
    if location is -1
      location = length
    location = Math.min(Math.max(location, 0), length)
    spanInfo = @getSpanInfoAtLocation(location, true)
    if location is length
      if item = spanInfo?.span.item
        each = item.nextItem
        while each and @getDisplayedSelfOrAncestor(each)
          item = each
          each = each.nextItem
        return {} =
          item: item
          offset: item.bodyString.length + 1
    {} =
      item: spanInfo?.span.item
      offset: spanInfo?.location

  getLocationForItemOffset: (item, offset) ->
    visibleItem = item
    while visibleItem and not @isDisplayed(visibleItem)
      visibleItem = visibleItem.previousItem
    if visibleItem isnt item
      offset = visibleItem?.bodyString.length + 1
      unless visibleItem
        return 0
    @getItemSpanForItem(visibleItem).getLocation() + offset

  replaceRange: (location, length, string, lineSpans) ->
    if location < 0 or (location + length) > @getLength()
      throw new Error("Invalide text range: #{location}-#{location + length}")

    if lineSpans
      for each in lineSpans
        assert(not each.isInOutline, 'Inserted items must be deteched first')

    @groupChanges null, =>
      selection = @editor?.selection

      if length > 0 and selection and selection.location is location and selection.length is length
        start = @getItemOffsetForLocation(location)
        startItem = start?.item
        end = @getItemOffsetForLocation(location + length)
        endItem = end?.item

        # If end item isn't visible then selection reaches end of buffer but
        # there are trailing items with visible ancestors. They should be
        # replaced in this case.
        unless @isDisplayed(endItem)
          assert(location + length == @getLength(), 'can only happen at end of buffer')
          endItem = @hoistedItem.nextBranch

        previouslySelectedItems = new Set()
        hiddenItems = []
        each = startItem
        while each isnt endItem
          if @isDisplayed(each)
            previouslySelectedItems.add(each)
          else if Selection.isSelectable(@, each, previouslySelectedItems)
            previouslySelectedItems.add(each)
            hiddenItems.push(each)
          each = each.nextItem
        @outline.removeItems(hiddenItems)

      super(location, length, string, lineSpans)

  ###
  Character attributes
  ###

  getAttributedString: (spanIndex, count) ->
    runSpans = []
    for each in @getSpans(spanIndex, count)
      spanString = each.getString()

      item = each.item
      itemAttributes =
        id: item.id
        parentID: item.parent.id
        attributes: item.attributes

      body = item.bodyHighlightedAttributedString
      bodyRunBuffer = body.runBuffer
      if bodyRunBuffer
        body.runBuffer.iterateRuns 0, body.runBuffer.getRunCount(), (run) ->
          attributes = Object.assign({}, run.attributes)
          attributes.item = itemAttributes
          runSpans.push
            string: run.string
            attributes: attributes
        if body.length isnt spanString.length
          runSpans.push
            string: '\n'
            attributes: (item: itemAttributes)
      else
        runSpans.push
          string: spanString
          attributes: (item: itemAttributes)
    runSpans

  getAttributesAtIndex: (location, effectiveRange, longestEffectiveRange) ->
    start = @getSpanInfoAtLocation(location, true)
    attributes = start.span.item.getBodyAttributesAtIndex(start.location, effectiveRange, longestEffectiveRange)
    if effectiveRange
      effectiveRange.location += start.spanLocation
    if longestEffectiveRange
      longestEffectiveRange.location += start.spanLocation
    attributes

  getBodyAttributeAtIndex: (attribute, location, effectiveRange, longestEffectiveRange) ->
    start = @getSpanInfoAtLocation(location, true)
    attribute = start.span.item.getBodyAttributesAtIndex(attribute, start.location, effectiveRange, longestEffectiveRange)
    if effectiveRange
      effectiveRange.location += start.spanLocation
    if longestEffectiveRange
      longestEffectiveRange.location += start.spanLocation
    attribute

  setAttributesInRange: (attributes, location, length) ->

  addAttributeInRange: (attribute, value, location, length) ->

  addAttributesInRange: (attributes, location, length) ->

  removeAttributeInRange: (attribute, location, length) ->

  ###
  Section: Serialization
  ###

  serializeRange: (location, length, options={}) ->
    startItemOffset = @getItemOffsetForLocation(location)
    endItemOffset = @getItemOffsetForLocation(location + length)
    startItem = startItemOffset.item
    startOffset = startItemOffset.offset
    endItem = endItemOffset.item
    endOffset = endItemOffset.offset
    previouslySelectedItems = new Set()
    serializeItems = []

    shouldSerializeItem = (item) =>
      if options.onlyDisplayed
        @isDisplayed(item)
      else
        if Selection.isSelectable(@, item, previouslySelectedItems)
          previouslySelectedItems.add(item)
          true
        else
          false

    each = startItem
    stopItem = endItem.nextItem
    while each isnt stopItem
      if shouldSerializeItem(each)
        serializeItems.push(each)
      each = each.nextItem

    if not shouldSerializeItem(startItem)
      startOffset = 0

    if not shouldSerializeItem(endItem)
      endOffset = serializeItems[serializeItems.length - 1]?.bodyString.length ? 0

    options['startOffset'] ?= startOffset
    options['endOffset'] ?= endOffset
    options['flattenItemHiearchy'] = false

    @serializeItems(serializeItems, options)

  serializeItems: (items, options={}) ->
    options.flattenItemHiearchy ?= true
    if items and options.flattenItemHiearchy
      items = Item.flattenItemHiearchy(items, false)
    items ?= @outline.root.descendants

    unless options.collapsedItems
      collapsedItems = []
      for each in items
        if @isCollapsed(each)
          collapsedItems.push(each)
      options.collapsedItems = collapsedItems

    ItemSerializer.serializeItems(items, options)

  deserializeItems: (serializedItems, options={}) ->
    try
      return ItemSerializer.deserializeItems(serializedItems, @outline, options)
    catch e
      return null

  ###
  Section: Item Spans
  ###

  createSpan: (text) ->
    item = @outline.createItem(text)
    item.indent = @hoistedItem.depth + 1
    @createSpanForItem(item)

  createSpanForItem: (item) ->
    new ItemSpan(item)

  getItemSpanForItem: (item) ->
    @_itemsToItemSpansMap.get(item)

  insertSpans: (spanIndex, itemSpans) ->
    if itemSpans.length is 0
      return

    hoistedDepth = @hoistedItem.depth
    for each in itemSpans
      assert(each.item.depth > hoistedDepth, 'Span item depth must be greater then hoisted item depth')
      @_itemsToItemSpansMap.set(each.item, each)
      if parent = each.item.parent
        @_invalidateItemCalculatedStyles.add(parent) # because collapsed state

    unless @isUpdatingIndex
      unless insertBefore = @getSpan(spanIndex)?.item
        # Inserting at end of buffer case
        if insertAfter = @lastDisplayedItem
          insertBefore = insertAfter.nextBranch
        else
          insertBefore = @hoistedItem.nextSibling

      items = (each.item for each in itemSpans)
      @beginUpdatingOutline()
      @outline.insertItemsBefore(items, insertBefore)
      @endUpdatingOutline()

    super(spanIndex, itemSpans)

  removeSpans: (spanIndex, removeCount) ->
    if removeCount is 0
      return

    lineSpans = []
    @iterateLines spanIndex, removeCount, (each) =>
      @_itemsToItemSpansMap.delete(each.item)
      if parent = each.item.parent
        @_invalidateItemCalculatedStyles.add(parent) # because collapsed state
      lineSpans.push(each)

    unless @isUpdatingIndex
      @beginUpdatingOutline()
      @outline.removeItems((each.item for each in lineSpans))
      @endUpdatingOutline()

    super(spanIndex, removeCount)

module.exports = ItemBuffer
