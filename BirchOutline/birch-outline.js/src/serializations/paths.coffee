deserializeItems = (pathList, outline, options) ->
  filenames = pathList.split('\n')
  if options.type == 'public.file-url'
    filenames = filenames.map (each) -> each.replace('file://', '')

  items = []
  for each in filenames
    item = outline.createItem()
    item.bodyString = decodeURI(each).trim().replace(/[ ]/g, '\\ ')
    items.push item
  items

module.exports =
  deserializeItems: deserializeItems
