class SpanLeaf

  constructor: (@children) ->
    @indexParent = null
    length = 0
    height = 0
    for each in @children
      each.indexParent = this
      length += each.getLength()
      height += each.getHeight()
    @length = length
    @height = height

  clone: ->
    children = []
    for each in @children
      children.push(each.clone())
    new @constructor(children)

  ###
  Section: Characters
  ###

  getLength: ->
    @length

  getString: ->
    strings = []
    for each in @children
      strings.push(each.getString())
    strings.join('')

  getLocation: (child) ->
    length = @indexParent?.getLocation(this) or 0
    if child
      for each in @children
        if each is child
          break
        length += each.getLength()
    length

  getSpanInfoAtLocation: (location, spanIndex=0, spanLocation=0, spanYOffset=0) ->
    for each in @children
      childLength = each.getLength()
      if location > childLength
        location -= childLength
        spanIndex++
        spanLocation += childLength
        spanYOffset += each.getHeight()
      else
        return {} =
          span: each
          location: location
          spanIndex: spanIndex
          spanLocation: spanLocation
          spanYOffset: spanYOffset

  ###
  Section: Y-Offset
  ###

  getHeight: ->
    @height

  getYOffset: (child) ->
    yOffset = @indexParent?.getYOffset(this) or 0
    if child
      for each in @children
        if each is child
          break
        yOffset += each.getHeight()
    yOffset

  getSpanInfoAtYOffset: (yOffset, spanIndex=0, spanLocation=0, spanYOffset=0) ->
    overshoot = Math.max(0, yOffset - @height)
    yOffset = Math.min(yOffset, @height)
    for each in @children
      childHeight = each.getHeight()
      if yOffset > childHeight
        yOffset -= childHeight
        spanIndex++
        spanLocation += each.getLength()
        spanYOffset += childHeight
      else
        return {} =
          span: each
          yOffset: yOffset + overshoot
          spanIndex: spanIndex
          spanLocation: spanLocation
          spanYOffset: spanYOffset

  ###
  Section: Spans
  ###

  getSpanCount: ->
    @children.length

  getSpan: (index) ->
    @children[index]

  getSpanIndex: (child) ->
    index = @indexParent?.getSpanIndex(this) or 0
    if child
      index += @children.indexOf(child)
    index

  iterateSpans: (start, count, operation) ->
    for i in [start...start + count]
      if operation(@children[i]) is false
        return false

  insertSpans: (index, spans) ->
    for each in spans
      each.indexParent = this
      @length += each.getLength()
      @height += each.getHeight()
    @children = @children.slice(0, index).concat(spans).concat(@children.slice(index))

  removeSpans: (start, removeCount) ->
    end = start + removeCount
    for i in [start...end]
      each = @children[i]
      each.indexParent = null
      @length -= each.getLength()
      @height -= each.getHeight()
    @children.splice(start, removeCount)

  ###
  Section: Util
  ###

  collapse: (spans) ->
    for each in @children
      spans.push(each)

module.exports = SpanLeaf
