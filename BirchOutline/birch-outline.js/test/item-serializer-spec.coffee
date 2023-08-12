loadOutlineFixture = require './load-outline-fixture'
ItemSerializer = require '../src/item-serializer'
Outline = require '../src/outline'
should = require('chai').should()

describe 'ItemSerializer', ->
  [outline, root, one, two, three, four, five, six] = []

  beforeEach ->
    {outline, root, one, two, three, four, five, six} = loadOutlineFixture()

  afterEach ->
    outline.destroy()

  it 'should normalize line breaks', ->
    ItemSerializer.replaceParagraphBreaks('\n', '').length.should.equal(0)
    ItemSerializer.replaceParagraphBreaks('\n\n', '').length.should.equal(0)
    ItemSerializer.replaceParagraphBreaks('\r', '').length.should.equal(0)
    ItemSerializer.replaceParagraphBreaks('\r\n', '').length.should.equal(0)
