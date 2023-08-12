{ AttributedString }  = require 'birch-outline'
LineSpan = require '../line-buffer/line-span'

class ItemSpan extends LineSpan

  constructor: (@item) ->
    super(@item.bodyString)
    @bodyAttributedStringClone = @item.bodyAttributedString.clone()

  clone: ->
    new @constructor(@item.clone(false))

  ###
  Section: Characters
  ###

  getLineContent: ->
    @string

  getLineContentSuffix: (location) ->
    @bodyAttributedStringClone.attributedSubstringFromRange(location, -1)

  replaceRange: (location, length, text) ->
    if text instanceof AttributedString
      string = text.string
    else
      string = text

    super(location, length, string)

    if root = @getRoot()
      unless root.isUpdatingIndex
        root.beginUpdatingOutline()
        @item.replaceBodyRange(location, length, text)
        root.endUpdatingOutline()
    else
      @item.replaceBodyRange(location, length, text)

    @bodyAttributedStringClone = @item.bodyAttributedString.clone()

  ###
  Section: Debug
  ###

  toString: ->
    super(@item.id)

module.exports = ItemSpan
