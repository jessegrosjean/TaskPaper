{ Outline, ItemSerializer } = require 'birch-outline'

module.exports =
  searches: new Outline(ItemSerializer.TaskPaperType)
  tags: new Outline(ItemSerializer.TaskPaperType)