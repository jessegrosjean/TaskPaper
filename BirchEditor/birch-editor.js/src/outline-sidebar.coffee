# Copyright (c) 2015 Jesse Grosjean. All rights reserved.

{ Mutation, ItemPath, ItemPathQuery, util }  = require 'birch-outline'
configurationOutlines = require './configuration-outlines'
OutlineSidebarItem = require './outline-sidebar-item'
{Emitter, CompositeDisposable} = require 'event-kit'
fuzzaldrinPlus = require 'fuzzaldrin-plus'

Birch = require './birch'

module.exports =
class OutlineSidebar

  constructor: (@outlineEditor) ->
    @emitter = new Emitter()

    @idsToSidebarItemsMap = new Map()
    @query = new ItemPathQuery(@outlineEditor.outline)
    @query.options = debounce: 300

    @query.queryFunction = (outline, contextItem) =>
      root = @vendSidebarItem('root')

      @homeItem = @vendSidebarItem(outline.root.id, 'home', 'Home', outline.root.id)
      root.appendChild(@homeItem)

      @projectsGroup = @vendSidebarItem('projects', 'group', 'Projects')
      root.appendChild(@projectsGroup)

      gatherProjectDescendants = (item, projects=[]) ->
        child = item.firstChild
        while child
          if child.getAttribute('data-type') is 'project'
            projects.push(child)
            gatherProjectDescendants(child, projects)
          child = child.nextSibling
        return projects

      projects = gatherProjectDescendants(outline.root).map (each) =>
        projectSidebarItem = @vendSidebarItem(each.id, 'project', each.bodyContentString, each.id)
        projectSidebarItem.depth = each.depth
        projectSidebarItem
      if projects.length > 0
        @projectsGroup.depth = -1
        projectAncestorStack = [@projectsGroup]
        for eachProject in projects
          while (parentProject = projectAncestorStack[projectAncestorStack.length - 1]) and (eachProject.depth <= parentProject.depth)
            projectAncestorStack.pop()
          parentProject.appendChild(eachProject)
          projectAncestorStack.push(eachProject)

      @searchesGroup = @vendSidebarItem('searches', 'group', 'Searches')
      root.appendChild(@searchesGroup)

      embeddedSearches = outline.evaluateItemPath('//@search')
      searchesOutline = configurationOutlines.searches
      sharedSearches = searchesOutline.evaluateItemPath('//@search')
      searches = embeddedSearches.concat(sharedSearches)

      if searches.length > 0
        for eachSearchItem in searches
          eachItemPathFilter = eachSearchItem.getAttribute('data-search')
          if eachItemPathFilter
            @searchesGroup.appendChild(@vendSidebarItem("search-#{eachSearchItem.id}", 'search', eachSearchItem.bodyContentString, eachItemPathFilter))

      @tagsGroup = @vendSidebarItem('tags', 'group', 'Tags')
      root.appendChild(@tagsGroup)
      for eachEntry in @getTagAttributeNamesToValues()
        eachTagLabel = "@#{eachEntry[0].substring(5)}"
        eachTagSidebarItem = @vendSidebarItem("tag-#{eachEntry[0]}", 'tag', eachTagLabel, eachTagLabel)
        @tagsGroup.appendChild(eachTagSidebarItem)

        tagValues = Array.from(eachEntry[1])
        tagValues.sort (a, b) ->
          a.localeCompare(b)

        for eachTagValue in tagValues
          if eachTagValue
            eachTagRepresentedObject = "#{eachTagLabel} contains[l] \"#{eachTagValue}\""
            eachTagSidebarItem.appendChild(@vendSidebarItem("tag-#{eachEntry[0]}+#{eachTagValue}", 'tag-value', eachTagValue, eachTagRepresentedObject))

      [root, root.branchHash]

    @query.start()

    @_selectedItem = @homeItem

    @subscriptions = new CompositeDisposable

    @subscriptions.add @outlineEditor.onDidChangeHoistedItem => @updateSelectionIfNeeded()
    @subscriptions.add @outlineEditor.onDidChangeFocusedItem => @updateSelectionIfNeeded()
    @subscriptions.add @outlineEditor.onDidChangeItemPathFilter => @updateSelectionIfNeeded()
    @subscriptions.add @outlineEditor.onDidDestroy => @destroy()

    @subscriptions.add configurationOutlines.searches.onDidChange => @query.run()
    @subscriptions.add configurationOutlines.tags.onDidChange => @query.run()

    @subscriptions.add @query.onDidDestroy => @destroy()
    @subscriptions.add @query.onDidChange =>
      @_selectedItem = @validatedSelectedItem
      @emitter.emit 'did-change-items'

  destroy: ->
    unless @destroyed
      @subscriptions.dispose()
      @emitter.emit 'did-destroy'
      @query.destroy()
      @destroyed = true

  ###
  Section: Events
  ###

  # Public: Invoke the given callback when the value (or descendent value) of
  # {::rootItem} changes.
  #
  # - `callback` {Function} to be called when there is a change.
  #   - `root` Root {SidebarItem}.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeItems: (callback) ->
    @emitter.on 'did-change-items', callback

  # Public: Invoke the given callback when the value of {::selectedItem}
  # changes.
  #
  # - `callback` {Function} to be called when the selection changes.
  #   - `item` Selected {SidebarItem}.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidChangeSelection: (callback) ->
    @emitter.on 'did-change-selection', callback

  # Public: Invoke the given callback when the sidebar is destroyed.
  #
  # - `callback` {Function} to be called when the sidebar is destroyed.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  ###
  Section: Selection
  ###

  shouldSelectItem: (item) ->
    return item.isSelectable

  Object.defineProperty @::, 'selectedItem',
    get: -> @_selectedItem
    set: (sidebarItem) ->
      if typeof sidebarItem is 'string'
        sidebarItem = @idsToSidebarItemsMap.get(sidebarItem)

      if @_selectedItem isnt sidebarItem
        @_selectedItem = sidebarItem
        @emitter.emit 'did-change-selection', @selectedItem

      if @_selectedItem.type is 'home' or @_selectedItem.type is 'project'
        @outlineEditor.focusedItem = @outlineEditor.outline.getItemForID(@_selectedItem.representedObject)
      else
        switch @_selectedItem.type
          when 'search', 'tag', 'tag-value'
            @outlineEditor.itemPathFilter = @_selectedItem.representedObject

  Object.defineProperty @::, 'validatedSelectedItem',
    get: ->
      hoistedItem = @outlineEditor.hoistedItem
      focusedItem = @outlineEditor.focusedItem
      itemPathFilter = @outlineEditor.itemPathFilter
      maintainHoistedItemWhenFilter = Birch.preferences.get('BMaintainHoistedItemWhenFiltering')
      maintainItemPathWhenHoisting = Birch.preferences.get('BMaintainItemPathFilterWhenHoisting')

      # Maintain selection if still valid
      if selectedItem = @attachedSidebarItemForID(@selectedItem?.id)
        if selectedItem.representedObject is focusedItem?.id
          return selectedItem
        if selectedItem.representedObject is itemPathFilter
          return selectedItem

      # Find new selection, matching focused items
      if focusedItem
        while focusedItem and not @attachedSidebarItemForID(focusedItem.id)
          focusedItem = focusedItem.parent
        if focusedItem
          return @idsToSidebarItemsMap.get(focusedItem.id)

      # Find new selection, matching search items
      if itemPathFilter
        if searchItem = @rootItem.find(null, null, null, itemPathFilter)
          return @idsToSidebarItemsMap.get(searchItem.id)

      while hoistedItem and not @attachedSidebarItemForID(hoistedItem.id)
        hoistedItem = hoistedItem.parent

      @idsToSidebarItemsMap.get(hoistedItem.id)

  singleAction: ->

  doubleAction: ->
    if @selectedItem
      if @selectedItem.type is 'project'
        item = @outlineEditor.outline.getItemForID(@selectedItem.representedObject)
        if @outlineEditor.focusedItem
          @outlineEditor.hoistedItem = item
        else
          @outlineEditor.focusedItem = item
      else
        switch @selectedItem.type
          when 'search', 'tag', 'tag-value'
            @outlineEditor.itemPathFilter = @_selectedItem.representedObject

  updateSelectionIfNeeded: ->
    validatedSelectedItem = @validatedSelectedItem
    if @selectedItem isnt validatedSelectedItem
      @_selectedItem = validatedSelectedItem
      @emitter.emit 'did-change-selection', @selectedItem

  ###
  Section: Items
  ###

  Object.defineProperty @::, 'rootItem',
    get: ->
      @query.results[0]

  persistentIDForItemID: (id) ->
    unless id?
      return

    if item = @outlineEditor.outline.getItemForID(id)
      item.branchContentID
    else
      id

  itemIDForPersistentID: (id) ->
    if item = @outlineEditor.outline.getItemForBranchContentID(id)
      item.id
    else
      id

  reloadImmediate: ->
    @query.run()

  matchItemFromIDs: (itemIDs, searchString) ->
    matchScore = 0
    matchItem = null
    for eachID in itemIDs
      each = @idsToSidebarItemsMap.get(eachID)
      eachScore = fuzzaldrinPlus.score(each.title, searchString)
      if eachScore > matchScore
        matchScore = eachScore
        matchItem = each
    matchItem

  attachedSidebarItemForID: (id) ->
    unless id
      null
    else
      item = @idsToSidebarItemsMap.get(id)
      if item?.root is @rootItem
        item
      else
        null

  vendSidebarItem: (id, type, title, representedObject) ->
    if item = @idsToSidebarItemsMap.get(id)
      util.assert(item.type == type, 'type for id should never change')
      item.reInit(title, representedObject)
    else
      item = new OutlineSidebarItem(id, type, title, representedObject)
      @idsToSidebarItemsMap.set(id, item)

    item

  ###
  Section: Search Items
  ###

  searchItemForID: (id) ->
    itemID = id.substring(7)
    @outlineEditor.outline.getItemForID(itemID) ? configurationOutlines.searches.getItemForID(itemID)

  updateSearchItem: (id, label, search, embedded) ->
    documentOutline = @outlineEditor.outline
    itemID = id.substring(7)
    item = documentOutline.getItemForID(itemID) ? configurationOutlines.searches.getItemForID(itemID)
    item.outline.groupUndoAndChanges ->
      item.bodyContentString = label
      item.setAttribute('data-search', search)
      if embedded and item.outline isnt documentOutline
        item.removeFromParent()
      else if not embedded and item.outline isnt configurationOutlines.searches
        item.removeFromParent()
    if not item.parent
      outline = if embedded then documentOutline else configurationOutlines.searches
      item = outline.importItem(item, true)
      @insertSearchItem(outline, item)

  createSearchItem: (label, search, embedded, referenceID='') ->
    outline = if embedded then @outlineEditor.outline else configurationOutlines.searches
    item = outline.createItem(label)
    item.setAttribute('data-search', search)
    referenceItemID = referenceID.substring(7)
    @insertSearchItem(outline, item, outline.getItemForID(referenceItemID))

  insertSearchItem: (outline, item, referenceItem) ->
    if referenceItem
      referenceItem.parent.insertChildrenBefore(item, referenceItem)
    else
      embeddedSearches = outline.evaluateItemPath('//@search')
      if last = embeddedSearches.pop()
        last.parent.insertChildrenBefore(item, last.nextSibling)
      else
        searchesProject = outline.createItem('Searches:')
        searchesProject.appendChildren(item)
        outline.root.appendChildren(searchesProject)

  ###
  Section: Tag Items
  ###

  getTagAttributeNamesToValues: ->
    tagsOutline = configurationOutlines.tags
    includeTags = tagsOutline.evaluateItemPath('/project Include Tags')[0]?.attributeNames ? []
    excludeTags = tagsOutline.evaluateItemPath('/project Exclude Tags')[0]?.attributeNames ? []
    tagsToValues = @outlineEditor.outline.getTagAttributeNamesToValues(includeTags, excludeTags)
    tagsToValues.filter (entry) ->
      entry[0] isnt 'data-type'
