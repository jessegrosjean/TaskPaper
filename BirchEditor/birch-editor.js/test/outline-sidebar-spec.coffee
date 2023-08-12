{ Outline, ItemSerializer }  = require 'birch-outline'
loadOutlineFixture = require './load-outline-fixture'
OutlineSidebar = require '../src/outline-sidebar'
OutlineEditor = require '../src/outline-editor'
should = require('chai').should()
simple = require 'simple-mock'

describe 'OutlineSidebar', ->
  [outline, root, one, two, three, four, five, six, editor, nativeEditor, itemBuffer, sidebar] = []

  beforeEach ->
    {outline, root, one, two, three, four, five, six} = loadOutlineFixture(ItemSerializer.TaskPaperType)
    editor = new OutlineEditor(outline)
    sidebar = new OutlineSidebar(editor)
    sidebar.query.options = {} # disable debounce
    nativeEditor = editor.nativeEditor
    OutlineEditor.addOutlineEditor(editor)
    itemBuffer = editor.itemBuffer
    one.setAttribute('data-type', 'project')
    two.setAttribute('data-type', 'project')
    five.setAttribute('data-type', 'project')
    six.setAttribute('data-search', '//not @done')

  afterEach ->
    outline.retainCount.should.equal(1)
    editor.nativeEditor.text.should.equal(itemBuffer.getString())
    editor.destroy()
    outline.destroy()
    outline.retainCount.should.equal(0)
    outline.isRetained().should.equal(false)
    Outline.outlines.length.should.equal(0)
    OutlineEditor.outlineEditors.length.should.equal(0)
    sidebar.destroyed.should.equal(true)
    simple.restore()

  it 'should select home by default', ->
    sidebar.selectedItem.should.equal(sidebar.homeItem)

  it 'should include projects in sidebar', ->
    sidebar.attachedSidebarItemForID(one.id).title.should.equal('one')
    sidebar.attachedSidebarItemForID(two.id).title.should.equal('two')
    sidebar.attachedSidebarItemForID(five.id).title.should.equal('five')

  it 'should not inclinde project unless all ancestors are also projects', ->
    one.setAttribute('data-type', 'task')
    should.not.exist(sidebar.attachedSidebarItemForID(one.id))
    should.not.exist(sidebar.attachedSidebarItemForID(two.id))
    should.not.exist(sidebar.attachedSidebarItemForID(five.id))

  it 'should not include in sidebar unless is project', ->
    should.not.exist(sidebar.idsToSidebarItemsMap.get(three.id))

  it 'should update hoistedItem and filter on user selection change', ->
    sidebar.selectedItem = outline.root.id
    sidebar.selectedItem.title.should.equal('Home')
    editor.hoistedItem.should.equal(outline.root)
    editor.itemPathFilter.should.equal('')

    sidebar.selectedItem = one.id
    sidebar.selectedItem.title.should.equal('one')
    editor.hoistedItem.should.equal(outline.root)
    editor.focusedItem.should.equal(one)
