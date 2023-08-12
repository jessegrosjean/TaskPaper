stringHash = require 'string-hash'
ChoicePaletteItem = require './choice-palette-item'

module.exports =
class OutlineSidebarItem extends ChoicePaletteItem

  constructor: (@id, @type, @title, @representedObject) ->
    super(@type, @title, @representedObject)
    @_idHash = stringHash(@id)
    @reInit(@title, @representedObject)

  reInit: (@title='', @representedObject) ->
    @_attributesHash = null
    @_childrenHash = null
    @_branchHash = null
    @parent = null
    for each in @children
      each.parent = null
    @children = []

  Object.defineProperty @::, 'attributesHash',
    get: ->
      unless @_attributesHash
        @_attributesHash = @_idHash
        @_attributesHash ^= stringHash(@title)
        @_attributesHash ^= stringHash(@representedObject ? '')
      @_attributesHash

  Object.defineProperty @::, 'childrenHash',
    get: ->
      unless @_childrenHash
        # Must be smarter way so that don't need to create array? If just xor
        # each._idHash problem is item order gets lost So same children in
        # different order will result in same hash.
        childrenIDs = (each.id for each in @children)
        childrenIDs.push(@id) # Include parent as part of hash
        @_childrenHash = stringHash(childrenIDs.join(''))
      @_childrenHash

  Object.defineProperty @::, 'branchHash',
    get: ->
      unless @_branchHash
        @_branchHash = @attributesHash
        @_branchHash ^= @childrenHash
        for each in @children
          @_branchHash ^= each.branchHash
      @_branchHash

  find: (id, type, title, representedObject) ->
    if (not id or id is @id) and (not type or type is @type) and (not title or title is @title) and (not representedObject or representedObject is @representedObject)
      return @

    for each in @children
      if match = each.find(id, type, title, representedObject)
        return match

    null
