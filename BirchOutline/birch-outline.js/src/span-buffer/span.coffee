_ = require 'underscore-plus'

class Span

  constructor: (@string='') ->
    @indexParent = null

  clone: ->
    new @constructor(@string)

  split: (location) ->
    if location is 0 or location is @getLength()
      return null

    clone = @clone()
    clone.deleteRange(0, location)
    @deleteRange(location, @getLength() - location)
    clone

  mergeWithSpan: (span) ->
    false

  ###
  Section: Characters
  ###

  getLocation: ->
    @indexParent.getLocation(this) or 0

  getLength: ->
    @string.length

  getEnd: ->
    @getLocation() + @getLength()

  getString: ->
    @string

  setString: (string='') ->
    replaceRange(0, @getLength(), string)

  deleteRange: (location, length) ->
    @replaceRange(location, length, '')

  insertString: (location, string) ->
    @replaceRange(location, 0, string)

  appendString: (string) ->
    @insertString(@getLength(), string)

  replaceRange: (location, length, string) ->
    delta = string.length - length

    if location is 0 and length is @string.length
      @string = string
    else
      @string = @string.substr(0, location) + string + @string.slice(location + length)

    if delta
      each = @indexParent
      while each
        each.length += delta
        each = each.indexParent
    @

  ###
  Section: Y-Offset
  ###

  getYOffset: ->
    @indexParent.getYOffset(this) or 0

  getHeight: ->
    @height ? 10

  setHeight: (height=0) ->
    delta = height - @getHeight()
    @height = height
    if delta
      each = @indexParent
      while each
        each.height += delta
        each = each.indexParent
    @

  ###
  Section: Spans
  ###

  getRoot: ->
    each = @indexParent
    while each
      if each.isRoot
        return each
      each = each.indexParent
    null

  getSpanIndex: ->
    @indexParent.getSpanIndex(this)

  getSpanCount: ->
    1

  ###
  Section: Debug
  ###

  toString: (extra) ->
    if extra
      "(#{@getString()}/#{extra})"
    else
      "(#{@getString()})"

module.exports = Span
