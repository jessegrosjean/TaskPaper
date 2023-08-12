{ Itme, Span, util } = require 'birch-outline'
assert = util.assert

class LineSpan extends Span

  constructor: (text) ->
    super(text)

  getLineContent: ->
    @string

  getLineContentSuffix: (location) ->
    @getLineContent().substr(location)

  getLength: ->
    @string.length + 1

  getString: ->
    @getLineContent() + '\n'

  setString: (string='') ->
    assert(string.indexOf('\n') is -1)
    super(string)

  deleteRange: (location, length) ->
    assert(location + length <= @string.length)
    super(location, length)

  insertString: (location, text) ->
    assert(text.indexOf('\n') is -1)
    super(location, text)

module.exports = LineSpan
