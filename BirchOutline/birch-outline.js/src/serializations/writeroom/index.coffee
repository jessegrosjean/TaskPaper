{ repeat } = require '../../util'
text = require '../text'

serializeItemBody = (item, bodyAttributedString, options, context) ->
  bodyString = bodyAttributedString.string
  context.lines.push(repeat('\t', item.depth - options.baseDepth) + bodyString)

deserializeItem = (itemString, outline) ->
  item = outline.createItem()
  indent = itemString.match(/^\t*/)[0].length + 1
  body = itemString.substring(indent - 1)
  item.indent = indent
  item.bodyString = body
  item

deserializeItems = (itemsString, outline, options={}) ->
  text.deserializeItems(itemsString, outline, options, deserializeItem)

module.exports =
  beginSerialization: text.beginSerialization
  beginSerializeItem: text.beginSerializeItem
  serializeItemBody: text.serializeItemBody
  endSerializeItem: text.endSerializeItem
  endSerialization: text.endSerialization
  emptyEncodeLastItem: text.emptyEncodeLastItem
  deserializeItems: text.deserializeItems
  itemPathTypes: {}
