# Copyright (c) 2015 Jesse Grosjean. All rights reserved.

{Emitter, CompositeDisposable} = require 'event-kit'
fuzzaldrinPlus = require 'fuzzaldrin-plus'

module.exports =
class ChoicePalette

  constructor: (@filterKey) ->
    @_filterQuery = ''
    @_choicePaletteItems = []
    @_matchingChoicePaletteItems = []
    @_topChoicePaletteItemIndex = null

  Object.defineProperty @::, 'choicePaletteItems',
    get: -> @_choicePaletteItems
    set: (choicePaletteItems) ->
      @_choicePaletteItems = choicePaletteItems ? []
      @_matchingChoicePaletteItems = null
      @_topChoicePaletteItemIndex = null

  Object.defineProperty @::, 'filterQuery',
    get: -> @_filterQuery
    set: (filterQuery) ->
      @_filterQuery = filterQuery ? ''
      @_matchingChoicePaletteItems = null
      @_topChoicePaletteItemIndex = null

  Object.defineProperty @::, 'topChoicePaletteItemIndex',
    get: ->
      unless @_topChoicePaletteItemIndex
        @matchingChoicePaletteItems
      @_topChoicePaletteItemIndex

  Object.defineProperty @::, 'matchingChoicePaletteItems',
    get: ->
      unless @_matchingChoicePaletteItems
        if @_filterQuery.length > 0
          @_topChoicePaletteItemIndex = -1
          parentsToChildren = new Map
          topChoiceItem = null
          inserted = new Set

          insertIntoTree = (item) ->
            if inserted.has(item)
              return
            if not item
              inserted.add(null)
              return
            parent = item.parent ? null
            insertIntoTree(parent)
            unless childrenList = parentsToChildren.get(parent)
              childrenList = []
              parentsToChildren.set(parent, childrenList)
            childrenList.push(item)
            inserted.add(item)

          flattenTree = (children, results) ->
            return unless children
            for each in children
              results.push(each)
              flattenTree(parentsToChildren.get(each), results)

          matches = fuzzaldrinPlus.filter(@choicePaletteItems, @filterQuery, key: @filterKey)
          for each in matches
            if each.isSelectable
              topChoiceItem ?= each
              insertIntoTree(each)

          @_matchingChoicePaletteItems = []
          flattenTree(parentsToChildren.get(null), @_matchingChoicePaletteItems)
          @_topChoicePaletteItemIndex = @_matchingChoicePaletteItems.indexOf(topChoiceItem)
        else
          @_matchingChoicePaletteItems = @choicePaletteItems
          @_topChoicePaletteItemIndex = -1
          for each, index in @_matchingChoicePaletteItems
            if each.isSelectable and @_topChoicePaletteItemIndex is -1
              @_topChoicePaletteItemIndex = index
      @_matchingChoicePaletteItems

  Object.defineProperty @::, 'numberOfMatchingChoicePaletteItems',
    get: -> @matchingChoicePaletteItems.length

  matchingChoicePaletteItemAtIndex: (index) ->
    choicePaletteItem = @matchingChoicePaletteItems[index]
    choicePaletteItem.titleMatchIndexes = fuzzaldrinPlus.match(choicePaletteItem.title, @filterQuery)
    choicePaletteItem
