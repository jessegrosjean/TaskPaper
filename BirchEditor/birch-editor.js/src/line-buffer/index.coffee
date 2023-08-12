{ SpanBuffer, util } = require 'birch-outline'
LineSpan = require './line-span'
assert = util.assert

class LineBuffer extends SpanBuffer

  constructor: (children) ->
    super(children)

  getLineCount: ->
    @spanCount

  getLine: (index) ->
    @getSpan(index)

  getLineIndex: (child) ->
    @getSpanIndex(child)

  getLines: (start, count) ->
    @getSpans(start, count)

  iterateLines: (start, count, operation) ->
    @iterateSpans(start, count, operation)

  insertLines: (start, lines) ->
    @insertSpans(start, lines)

  removeLines: (start, removeCount) ->
    @removeSpans(start, removeCount)

  createLine: (text) ->
    @createSpan(text)

  createSpan: (text) ->
    new LineSpan(text)

  replaceRange: (location, length, string, lineSpans) ->
    end = location + length
    bufferLength = @getLength()

    if location < 0 or end > bufferLength
      throw new Error("Invalide text range: #{location}-#{end}")

    if @emitter and not @scheduledChangeEvent
      insertedString = string
      if end is bufferLength
        insertedString += '\n'
      changeEvent =
        location: location
        replacedLength: length
        insertedString: insertedString
        insertedSpans: []
        removedSpans: []

    lines = string.split('\n')
    lineSpans ?= (@createSpan(each) for each in lines)

    @groupChanges changeEvent, =>
      start = @getSpanInfoAtLocation(location, true)
      if not start or location is bufferLength
        assert(length is 0)
        @insertSpans(@getSpanCount(), lineSpans)
      else
        end = @getSpanInfoAtLocation(end, true)

        # Simple replace in single span
        if start.span is end.span and lineSpans.length is 1
          end = start.location + length
          if length and end is start.span.getLength()
            length-- # Correct for trailing \n, never want to replace that range.
          start.span.replaceRange(start.location, length, lineSpans[0].getLineContentSuffix(0))

        # Special case. If replaced spans are fully selected just remove them,
        # and insert new.
        else if start.location is 0 and start.span isnt end.span and end.location is 0
          end.span.replaceRange(0, end.location, lineSpans.pop().getLineContentSuffix(0))
          @removeSpans(start.spanIndex, end.spanIndex - start.spanIndex)
          @insertLines(start.spanIndex, lineSpans)

        # Full case. Insert into the first selected span, deleting trailing
        # selected spans. Then insert new.
        else
          endSuffix = end.span.getLineContentSuffix(end.location)
          start.span.replaceRange(start.location, start.span.getLineContent().length - start.location, lineSpans.shift().getLineContentSuffix(0))
          @removeSpans(start.spanIndex + 1, end.spanIndex - start.spanIndex)
          @insertLines(start.spanIndex + 1, lineSpans)
          if endSuffix.length
            lastSpan = lineSpans.pop() ? start.span
            lastSpan.replaceRange(lastSpan.getLineContent().length, 0, endSuffix)

module.exports = LineBuffer
