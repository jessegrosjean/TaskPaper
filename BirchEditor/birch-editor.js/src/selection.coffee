# Copyright (c) 2015 Jesse Grosjean. All rights reserved.

{ Item }  = require 'birch-outline'

# Public: Read-only selection snapshot from {OutlineEditor::selection}.
#
# This selection can not be changed and will not update when the outline or
# editor selection changes. Use {OutlineEditor::moveSelectionToItems} or
# {OutlineEditor::moveSelectionToRange} to change the editor's selection.
#
# The selection character offsets are always valid, but in some cases the
# selection endpoint {Item}s maybe be null. For instance if the
# {OutlineEditor} has hoisted an item that has no children then the character
# selection will be `0,0`, but {::startItem} and {::endItem} will be `null`.
#
# The {::endItem} end point isn't always the last item in {::selectedItems}.
# For example if {::endItem} doesn't equal {::startItem} and {::endOffset} is
# 0 then {::endItem} isn't included in the selected items because it doesn't
# overlap the selection, it's just an endpoint anchor, not a selcted item.
module.exports =
class Selection

  constructor: (@editor, @start, @end, @startItem, @startOffset, @endItem, @endOffset) ->

  ###
  Section: Selection
  ###

  # Public: Read-only true if selection start equals end.
  isCollapsed: null
  Object.defineProperty @::, 'isCollapsed',
    get: -> @startItem is @endItem and @startOffset is @endOffset

  # Public: Read-only true if selection starts at item start boundary and ends
  # at item end boundary.
  isFullySelectingItems: null
  Object.defineProperty @::, 'isFullySelectingItems',
    get: ->
      if @startItem
        @startOffset is 0 and @endOffset is 0 and @endItem is @startItem.nextItem
      else
        true

  ###
  Section: Characters
  ###

  # Public: Read-only selection start character offset.
  start: null

  # Public: Read-only selection end character offset.
  end: null

  # Public: Read-only selection character location offset.
  location: null
  Object.defineProperty @::, 'location',
    get: -> @start

  # Public: Read-only selection character length.
  length: null
  Object.defineProperty @::, 'length',
    get: -> @end - @start

  ###
  Section: Items
  ###

  # Public: Read-only selection start {Item} (or null) in outline order.
  startItem: null

  # Public: Read-only text offset in the {::startItem} where selection starts.
  startOffset: undefined

  # Public: Read-only selection endpoint {Item} (or null) in outline order.
  endItem: null

  # Public: Read-only text offset endpoint in {::endItem} or undefined.
  endOffset: undefined

  # Public: Read-only {Array} of {Item}s intersecting the selection. Does not
  # include {::endItem} if {::endItem} doesn't equal {::startItem} and
  # {::endOffset} is 0. Does include all overlapped outline items, including
  # folded and hidden ones, between the start and end items.
  selectedItems: null
  Object.defineProperty @::, 'selectedItems',
    get: ->
      selectedItems = []
      @forEachItem (item, location, length, fullySelected) ->
        selectedItems.push(item)
      selectedItems

  # Public: Read-only {Array} of displayed {Item}s intersecting the selection.
  # Does not include {::endItem} if {::endItem} doesn't equal {::startItem}
  # and {::endOffset} is 0. Does not include items that the selection overlaps
  # but that are hidden in the editor.
  displayedSelectedItems: null
  Object.defineProperty @::, 'displayedSelectedItems',
    get: ->
      results = []
      for each in @selectedItems
        if @editor.isDisplayed(each)
          results.push(each)
      results

  # Public: Read-only {Array} of displayed {Item}s intersecting the selection.
  # Does not include {::endItem} if {::endItem} doesn't equal {::startItem}
  # and {::endOffset} is 0. Does include items that overlap the selection by
  # that are not visible.
  displayedAncestorSelectedItems: null
  Object.defineProperty @::, 'displayedAncestorSelectedItems',
    get: ->
      results = []
      for each in @selectedItems
        if @editor.getDisplayedSelfOrAncestor(each)
          results.push(each)
      results

  trailingHiddenDescendentItems: null
  Object.defineProperty @::, 'trailingHiddenDescendentItems',
    get: ->
      trailingCollapsed = []
      selectedItems = @selectedItems
      last = selectedItems[selectedItems.length - 1]
      end = last?.nextBranch
      each = last?.nextItem
      while each isnt end
        if @editor.isDisplayed(each)
          return trailingCollapsed
        else
          trailingCollapsed.push(each)
        each = each.nextItem
      trailingCollapsed

  # Public: Read-only {Array} of the common ancestors of {::selectedItems}.
  selectedItemsCommonAncestors: null
  Object.defineProperty @::, 'selectedItemsCommonAncestors',
    get: -> Item.getCommonAncestors(@selectedItems)

  @calculatedSelectedItems: (editor, startItem, startOffset, endItem, endOffset) ->
    selectedItems = []
    callback = (item, location, length, fullySelected) ->
      selectedItems.push(item)
    @forEachCalculatedSelectedItem(editor, startItem, startOffset, endItem, endOffset, callback)
    selectedItems

  @isSelectable: (editor, item, previouslySelectedItems) ->
    if editor.isDisplayed(item)
      true
    else
      each = item?.parent
      while each and each isnt editor.hoistedItem
        if previouslySelectedItems.has(each)
          return true
        each = each.parent
      false

  @forEachCalculatedSelectedItem: (editor, startItem, startOffset, endItem, endOffset, callback) ->
    previouslySelectedItems = new Set()

    if startItem is endItem
      if startItem
        if @isSelectable(editor, startItem, previouslySelectedItems)
          previouslySelectedItems.add(startItem)
          callback(startItem, startOffset, endOffset - startOffset, false)
    else
      each = startItem.nextItem
      if @isSelectable(editor, startItem, previouslySelectedItems)
        previouslySelectedItems.add(startItem)
        callback(startItem, startOffset, each.bodyString.length - startOffset, false)
      while each isnt endItem
        if @isSelectable(editor, each, previouslySelectedItems)
          previouslySelectedItems.add(each)
          callback(each, 0, each.bodyString.length, true)
        each = each.nextItem
      if endOffset > 0
        if @isSelectable(editor, endItem, previouslySelectedItems)
          previouslySelectedItems.add(endItem)
          callback(endItem, 0, endOffset, false)

  forEachItem: (callback) ->
    Selection.forEachCalculatedSelectedItem(@editor, @startItem, @startOffset, @endItem, @endOffset, callback)

  prepareForMove: ->
    return unless @startItem
    if @endItem isnt @startItem and @endOffset is 0
      @savedFullySelectedEnd = @endItem.previousItem
    else if @endOffset is @endItem.bodyString.length + 1
      @savedFullySelectedEnd = @endItem

  restoreAfterMove: ->
    if @savedFullySelectedEnd
      @endItem = @savedFullySelectedEnd.nextItem
      if @endItem
        @endOffset = 0
      else
        @endItem = @savedFullySelectedEnd
        @endOffset = @savedFullySelectedEnd.bodyString.length + 1
      @savedFullySelectedEnd = undefined

  selectionByExtendingToItem: (editor) ->
    unless @startItem
      return new Selection(@editor, 0, 0)

    endItem = @endItem
    endOffset = endItem.bodyString.length

    if not @isCollapsed and @endOffset is 0
      endOffset = 0
    else
      nextItem = endItem.nextItem
      if nextItem
        endItem = nextItem
        endOffset = 0

    new Selection(@editor, null, null, @startItem, 0, endItem, endOffset)

  selectionByExtendingToBranch: (editor) ->
    unless @startItem
      return new Selection(@editor, 0, 0)

    commonAncestors = @selectedItemsCommonAncestors
    last = commonAncestors[commonAncestors.length - 1].lastBranchItem
    next = last.nextItem
    if next
      new Selection(@editor, null, null, commonAncestors[0], 0, next, 0)
    else
      new Selection(@editor, null, null, commonAncestors[0], 0, last, last.bodyString.length)

  toString: ->
    "#{@start},#{@end}"
