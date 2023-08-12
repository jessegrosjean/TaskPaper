{ util } = require 'birch-outline'
assert = util.assert

module.exports =
class OutlineEditorNative
  constructor: (@editor, @text='') ->
    @editing = 0
    @selectedRange =
      location: 0
      length: 0

  Object.defineProperty @::, 'isEditing',
    get: -> @editing > 0

  Object.defineProperty @::, 'visibleRect',
    get: ->
      x: 0, y: beforeY, width: 100, height: 0

  Object.defineProperty @::, 'scrollPoint',
    get: ->
      x: 0, y: 0
    set: (scrollPoint) ->
      @_setScrollPoint(scrollPoint)

  _setScrollPoint: (scrollPoint) -> # for spy
    assert(@editing is 0, 'cant be editing when set scrollPoint')

  Object.defineProperty @::, 'selectedRange',
    get: ->
      @_selectedRange.location = Math.min(@_selectedRange.location, @text.length)
      @_selectedRange.length = Math.min(@_selectedRange.length, @text.length - @_selectedRange.location)
      @_selectedRange
    set: (selectedRange) ->
      @_setSelectedRange(selectedRange)

  _setSelectedRange: (@_selectedRange) -> # for spy
    @validateRange(@_selectedRange)
    assert(@editing is 0, 'cant be editing when set selectedRange')
    @editor.emitter.emit 'did-change-selection'

  getRectForRange:(range) ->
    @validateRange(range)
    assert(@editing is 0, 'cant be editing when getRectForRange')
    beforeRange = @text.substr(0, range.location)
    beforeY = (beforeRange.split('\n').length - 1) * 10
    inRange = @text.substr(range.location, range.length)
    inHeight = inRange.split('\n').length * 10
    x: 0, y: beforeY, width: 100, height: inHeight

  getCharacterIndexForPoint: (point) ->
    return Math.floor(Math.random() * @text.length)

  scrollRangeToVisible: (range) ->
    assert(@editing is 0, 'cant be editing when scrollRangeToVisible')
    @validateRange(range)
    rect = @getRectForRange(range)
    @scrollPoint = x: rect.x, y: rect.y

  invalidateRestorableState: ->

  beginEditing: ->
    @editing++

  setHoistedItem: (item) ->

  invalidateRange: (range) ->
    assert(@editing > 0, 'must be editing when invalidateItem')
    @validateRange(range)

  replaceCharactersInRangeWithString: (range, text) ->
    @validateRange(range)
    assert(@editing > 0, 'must be editing when replaceCharactersInRangeWithString')
    @text = @text.substring(0, range.location) + text + @text.substring(range.location + range.length)

  endEditing: ->
    @editing--
    if @editing is 0
      @_didEndEditing()

  _didEndEditing: -> # for spy

  focus: ->

  validateRange: (range) ->
    assert(range.location <= @text.length)
    assert(range.location + range.length <= @text.length)

  getDateFromUserDateStringTemplateCallback: (placeholder, stringTemplate, callback) ->
    '1976-11-27'

  getItemAttributesFromUserCallback: (placeholder, callback) ->
    callback?(['data-done'])

  importRemindersWithCallback: (callback) ->
    callback?(true)

  exportToRemindersWithCallback: (callback) ->
    callback?(true)

  exportCopyToRemindersWithCallback: (callback) ->
    callback?(true)
