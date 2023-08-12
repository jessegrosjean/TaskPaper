module.exports =
class ChoicePaletteItem

  constructor: (@type, @title, @representedObject) ->
    @parent = null
    @children = []

  Object.defineProperty @::, 'root',
    get: ->
      each = @
      while each.parent
        if each.parent.children.indexOf(each) isnt -1
          each = each.parent
        else
          return each
      each

  Object.defineProperty @::, 'isGroup',
    get: ->
      @type is 'group'

  Object.defineProperty @::, 'isSelectable',
    get: ->
      @type isnt 'group' and @type isnt 'label'

  appendChild: (child) ->
    child.parent = @
    @children.push(child)
