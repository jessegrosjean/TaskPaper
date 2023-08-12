loadOutlineFixture = require './load-outline-fixture'
OutlineEditor = require '../src/outline-editor'
StyleSheet = require '../src/style-sheet'
{ Outline }  = require 'birch-outline'
Birch = require '../src/birch'
simple = require 'simple-mock'

lessRules = """
  editor {
    color: red;
    background-color: green;
    font-style: normal;
    font-weight: normal;
    font-family: Jesse;
    font-size: 20;
    line-height-multiple: 1.1;
  }
  item {
    handle-color: blue;
  }
  item[data-done] > run {
    color: grey;
    text-strikethrough: NSUnderlineStyleSingle;
  }
  run[A] {
    text-underline: NSUnderlineStyleSingle;
  }
"""

describe 'OutlineEditor', ->
  [outline, root, one, two, three, four, five, six, styleSheet, editor, nativeEditor, itemBuffer] = []

  beforeEach ->
    {outline, root, one, two, three, four, five, six} = loadOutlineFixture()
    styleSheet = new StyleSheet(lessRules)
    editor = new OutlineEditor(outline, styleSheet)
    nativeEditor = editor.nativeEditor
    OutlineEditor.addOutlineEditor(editor)
    itemBuffer = editor.itemBuffer

  afterEach ->
    outline.retainCount.should.equal(1)
    editor.nativeEditor.text.should.equal(itemBuffer.getString())
    editor.destroy()
    outline.destroy()
    outline.retainCount.should.equal(0)
    outline.isRetained().should.equal(false)
    Outline.outlines.length.should.equal(0)
    OutlineEditor.outlineEditors.length.should.equal(0)
    simple.restore()

  describe 'View', ->

    describe 'Focus Items', ->

      it 'should validate selection index when focus items', ->
        editor.moveSelectionToItems(six)
        editor.focusedItem = three
        itemBuffer.getString().should.equal('three\n')

    describe 'Expand & Collapse Items', ->

      it 'items should be expanded by default', ->
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')
        editor.isExpanded(one).should.be.true

      it 'should hide children when item is collapsed', ->
        editor.setCollapsed(one)
        editor.isExpanded(one).should.be.false
        editor.isDisplayed(two).should.be.false
        editor.isDisplayed(five).should.be.false
        itemBuffer.getString().should.equal('one\n')

      it 'should show children when visible item is expanded', ->
        editor.setCollapsed(one)
        editor.setExpanded(one)
        editor.isExpanded(one).should.be.true
        editor.isDisplayed(two).should.be.true
        editor.isDisplayed(five).should.be.true
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

      it 'should expand mutliple items at once', ->
        editor.setCollapsed([one, two, five])
        editor.setExpanded([one, two, five])
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

      it 'should expand selected items ', ->
        editor.setCollapsed([two, five])
        editor.moveSelectionToItems(two, 1, five, 2)
        itemBuffer.getString().should.equal('one\ntwo\nfive\n')
        editor.setExpanded()
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

      describe 'Expansion Levels', ->

        beforeEach ->
          three.appendChildren(four)

        it 'should get expansion level', ->
          editor.getExpansionLevel().should.equal(4)
          editor.setCollapsed(three)
          editor.getExpansionLevel().should.equal(3)
          editor.setCollapsed(two)
          editor.getExpansionLevel().should.equal(3)
          editor.setCollapsed(five)
          editor.getExpansionLevel().should.equal(2)
          editor.setCollapsed(one)
          editor.getExpansionLevel().should.equal(1)

        it 'should set expansion level', ->
          editor.setExpansionLevel(1)
          itemBuffer.getString().should.equal('one\n')
          editor.setExpansionLevel(2)
          itemBuffer.getString().should.equal('one\ntwo\nfive\n')
          editor.setExpansionLevel(3)
          itemBuffer.getString().should.equal('one\ntwo\nthree\nfive\nsix\n')
          editor.setExpansionLevel(4)
          itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

        it 'should decreaseExpansionLevel expansion level', ->
          editor.decreaseExpansionLevel()
          itemBuffer.getString().should.equal('one\ntwo\nthree\nfive\nsix\n')

    describe 'Style Calculations', ->

      it 'should calculate editor style', ->
        editor.getComputedStyle().should.eql({ 'background-color': [ 0, 128, 0, 1 ], color: [ 255, 0, 0, 1 ], 'font-family': ['Jesse'], 'font-size': 20, 'font-style': 'normal', 'font-weight': 'normal', 'line-height-multiple': 1.1 })

      it 'should calculate item style', ->
        keyPath = editor.getComputedStyleKeyPathForItem(one)
        keyPath.should.equal('id-0>id-1')
        editor.styleSheet.getComputedStyleForKeyPath(keyPath).should.eql({ 'handle-color': [ 0, 0, 255, 1 ], color: [ 255, 0, 0, 1 ], 'font-family': ['Jesse'], 'font-size': 20, 'font-style': 'normal', 'font-weight': 'normal', 'line-height-multiple': 1.1 })

      it 'should calculate run style', ->
        one.addBodyAttributeInRange('a', 'www.apple.com', 0, 1)
        editor.getComputedStyleKeyPathForItem(one)
        keyPath = editor.getComputedStyleKeyPathForItemRun(one, one.bodyAttributedString.getRuns()[1])
        keyPath.should.equal('id-0>id-1>*')
        editor.styleSheet.getComputedStyleForKeyPath(keyPath).should.eql({ color: [ 255, 0, 0, 1 ], 'font-family': ['Jesse'], 'font-size': 20, 'font-style': 'normal', 'font-weight': 'normal', 'line-height-multiple': 1.1 })

    describe 'Guides and Gaps', ->

      it 'should calculate guide ranges', ->
        editor.getGuideRangesForVisibleRange(0, editor.textLength).should.eql([0, 28, 4, 15, 19, 9])

      it 'should have no gap locations when there are no gaps', ->
        editor.getGapLocationsForVisibleRange(0, editor.textLength).should.eql([])

      it 'should have gap location when there is visible ancestor for items in gaps', ->
        two.appendChildren([five])
        editor.forceHidden(four)
        editor.getGapLocationsForVisibleRange(0, editor.textLength).should.eql([8, 0])

      it 'should not select gap unless visible ancestor is selected', ->
        two.appendChildren([five])
        editor.forceHidden(four)
        editor.moveSelectionToItems(three, 0, five, 0)
        editor.getGapLocationsForVisibleRange(0, editor.textLength).should.eql([8, 0])

      it 'should show gap for last collapsed item', ->
        editor.setCollapsed(one)
        editor.moveSelectionToRange(0, 4)
        editor.getGapLocationsForVisibleRange(0, editor.textLength).should.eql([0, 1])

  describe 'Insert', ->

    it 'should insert new empty item if existing is selected at end', ->
      editor.moveSelectionToItems(two, 3)
      editor.insertNewline()
      inserted = two.nextItem
      inserted.bodyString.should.equal('')
      inserted.depth.should.equal(3)
      editor.selection.toString().should.eql('8,8')
      itemBuffer.getString().should.equal('one\ntwo\n\nthree\nfour\nfive\nsix\n')

    it 'should insert new split from current if selection is in middle', ->
      editor.moveSelectionToItems(two, 1, two, 2)
      editor.insertNewline()
      editor.selection.toString().should.eql('6,6')
      itemBuffer.getString().should.equal('one\nt\no\nthree\nfour\nfive\nsix\n')

    it 'should skip over folded content and insert before next visible item', ->
      editor.setCollapsed([two])
      editor.moveSelectionToItems(two, 1)
      editor.insertNewline()
      inserted = four.nextItem
      inserted.bodyString.should.equal('wo')
      inserted.depth.should.equal(2)
      editor.selection.toString().should.eql('6,6')
      itemBuffer.getString().should.equal('one\nt\nwo\nfive\nsix\n')

    it 'should insert new line in empty document', ->
      one.removeFromParent()
      editor.insertNewline()
      editor.insertNewline()
      itemBuffer.getString().should.equal('\n\n')

    it 'should insert new item at end of indented list', ->
      editor.moveSelectionToItems(four, 4)
      editor.insertNewline()
      inserted = four.nextItem
      inserted.bodyString.should.equal('')
      inserted.depth.should.equal(four.depth)
      editor.selection.toString().should.eql('19,19')
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\n\nfive\nsix\n')

    it 'should insert new item at end of list', ->
      editor.moveSelectionToItems(six, 3)
      editor.insertNewline()
      inserted = six.nextItem
      inserted.bodyString.should.equal('')
      inserted.depth.should.equal(3)
      editor.selection.toString().should.eql('28,28')
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n\n')

    it 'should skip over folded content and insert before next visible item when item is partially collpased', ->
      editor.setCollapsed([two])
      editor.moveSelectionToItems(five, 1)
      editor.moveLinesRight()
      editor.moveSelectionToItems(two, 1)
      editor.insertNewline()
      inserted = four.nextItem
      inserted.bodyString.should.equal('wo')
      inserted.depth.should.equal(3)
      itemBuffer.getString().should.equal('one\nt\nwo\nfive\nsix\n')

    it 'should insert empty above current (move current down) if selection at start', ->
      editor.moveSelectionToItems(two, 0)
      editor.insertNewline()
      itemBuffer.getLine(2).item.should.equal(two)
      editor.selection.toString().should.eql('5,5')
      itemBuffer.getString().should.equal('one\n\ntwo\nthree\nfour\nfive\nsix\n')

    it 'should insert newline ignoring field editor', ->
      editor.moveSelectionToItems(three, 5)
      editor.insertNewlineWithoutIndent()
      itemBuffer.getLine(3).item.depth.should.equal(1)
      editor.selection.toString().should.eql('14,14')
      itemBuffer.getString().should.equal('one\ntwo\nthree\n\nfour\nfive\nsix\n')

    it 'should insert newline ignoring field editor at end of list', ->
      editor.moveSelectionToItems(four, 4)
      editor.insertNewlineWithoutIndent()
      itemBuffer.getLine(4).item.depth.should.equal(1)
      editor.selection.toString().should.eql('19,19')
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\n\nfive\nsix\n')

    it 'should insert newline after collapsed and before filtered', ->
      one.appendChildren(outline.createItem('child'))
      root.appendChildren([two, five])
      editor.itemPathFilter = 'one or six'
      editor.moveSelectionToItems(one, 3)
      editor.insertNewline()
      editor.itemPathFilter = ''
      itemBuffer.getString().should.equal('one\nchild\n\ntwo\nthree\nfour\nfive\nsix\n')

    it 'should autoformat list items', ->
      one.bodyString = '- one'
      Birch.preferences.set('BAutoformatListsAsYouType', true)
      editor.moveSelectionToRange(4, 4)
      editor.insertNewline()
      one.firstChild.bodyString.should.equal('- e')

    it 'should not autoformat list items unless they start with dash space', ->
      one.bodyString = 'o - ne'
      Birch.preferences.set('BAutoformatListsAsYouType', true)
      editor.moveSelectionToRange(6, 6)
      editor.insertNewline()
      one.firstChild.bodyString.should.equal('')

  describe 'Serialize', ->

    it 'should serialize empy range', ->
      editor.serializeRange(0, 0, type: 'text/plain').should.equal('')

    it 'should serialize range in single item', ->
      editor.serializeRange(0, 1, type: 'text/plain').should.equal('o')

    it 'should serialize range in single indented item', ->
      editor.serializeRange(5, 1, type: 'text/plain').should.equal('w')

    it 'should serialize full item in plain text', ->
      editor.serializeRange(0, 4, type: 'text/plain').should.equal('one\n')

    it 'should serialize range accross multiple items', ->
      editor.serializeRange(2, 4, type: 'text/plain').should.equal('e\n\ttw')

    it 'should serialize range accross multiple indented items', ->
      editor.serializeRange(5, 4, type: 'text/plain').should.equal('wo\n\tt')

    it 'should serialize range accross hidden items including collapsed items by default', ->
      editor.setCollapsed(two)
      length = itemBuffer.getString().length
      editor.serializeRange(0, length, type: 'text/plain').should.equal('one\n\ttwo\n\t\tthree\n\t\tfour\n\tfive\n\t\tsix')
      editor.serializeRange(4, 4, type: 'text/plain').should.equal('two\n\tthree\n\tfour\n')

    it 'should serialize range accross hidden items skipping hidden items with no visible ancestor', ->
      root.appendChildren([two, five])
      editor.itemPathFilter = 'one or six'
      length = itemBuffer.getString().length
      editor.serializeRange(0, length, type: 'text/plain').should.equal('one\nfive\n\tsix')

    it 'should serialize range to include trailing collapsed items', ->
      editor.setCollapsed([two, five])
      length = itemBuffer.getString().length
      editor.serializeRange(0, length, type: 'text/plain').should.equal('one\n\ttwo\n\t\tthree\n\t\tfour\n\tfive\n\t\tsix')

    it 'should serialize range accross hidden items ignoring collapsed items', ->
      editor.setCollapsed(two)
      length = itemBuffer.getString().length
      editor.serializeRange(0, length, type: 'text/plain', onlyDisplayed: true).should.equal('one\n\ttwo\n\tfive\n\t\tsix')
      editor.serializeRange(4, 4, type: 'text/plain', onlyDisplayed: true).should.equal('two\n')
      editor.serializeRange(5, 5, type: 'text/plain', onlyDisplayed: true).should.equal('wo\nfi')

    it 'should skip items with no visible ancestor when serilizing', ->
      root.appendChildren([two, three, four, five, six])
      editor.itemPathFilter = '//* except (two or six)///*'
      length = itemBuffer.getString().length
      editor.serializeRange(0, length, type: 'text/plain', onlyDisplayed: true).should.equal('one\nthree\nfour\nfive')

  describe 'Restorable State', ->

    it 'should encode and decode restorable state', ->
      editor.setCollapsed([one, two, five])
      editor.hoistedItem = one
      editor.focusedItem = two
      state = editor.restorableState

      editor.hoistedItem = null
      editor.focusedItem = null
      editor.setExpanded([one, two, five])

      editor.restorableState = state
      editor.isCollapsed(one).should.be.true
      editor.isCollapsed(five).should.be.true
      editor.isExpanded(two).should.be.true # since hoisted on save state
      editor.hoistedItem.should.equal(one)
      editor.focusedItem.should.equal(two)

    it 'should encode and decode restorable state after edits', ->
      editor.setCollapsed([one, two, five])
      editor.hoistedItem = one
      editor.focusedItem = two
      state = editor.restorableState

      editor.hoistedItem = null
      editor.focusedItem = null
      editor.setExpanded([one, two, five])
      root.insertChildrenBefore(outline.createItem('hello'), one)

      editor.restorableState = state
      editor.isCollapsed(one, true).should.be.true
      editor.isCollapsed(five, true).should.be.true
      editor.isExpanded(two, true).should.be.true # since hoisted on save state
      editor.hoistedItem.should.equal(one)
      editor.focusedItem.should.equal(two)

    it 'should encode and decode serialized restorable state', ->
      editor.setCollapsed([one, two, five])
      editor.hoistedItem = one
      editor.focusedItem = two
      state = editor.serializedRestorableState

      editor.hoistedItem = null
      editor.focusedItem = null
      editor.setExpanded([one, two, five])

      editor.serializedRestorableState = state
      editor.isCollapsed(one).should.be.true
      editor.isCollapsed(five).should.be.true
      editor.isExpanded(two).should.be.true # since hoisted on save state
      editor.hoistedItem.should.equal(one)
      editor.focusedItem.should.equal(two)

  describe 'Replace Range', ->

    it 'should replace folded items with visible ancestors when fully selected', ->
      editor.setCollapsed(two)
      editor.moveSelectionToRange(4, 8)
      editor.backspace()
      itemBuffer.getString().should.equal('one\nfive\nsix\n')
      two.isInOutline.should.not.be.ok
      three.isInOutline.should.not.be.ok
      four.isInOutline.should.not.be.ok
      five.isInOutline.should.be.ok

    it 'should replace folded items with visible ancestors when partially selected', ->
      editor.setCollapsed(two)
      editor.moveSelectionToRange(5, 8)
      editor.backspace()
      itemBuffer.getString().should.equal('one\ntfive\nsix\n')
      two.isInOutline.should.be.ok
      three.isInOutline.should.not.be.ok
      four.isInOutline.should.not.be.ok
      five.isInOutline.should.not.be.ok

    it 'should not replace folded items without visible ancestors', ->
      root.appendChildren([two, five])
      editor.itemPathFilter = '//* except two///*'
      editor.moveSelectionToRange(0, 12)
      editor.backspace()
      itemBuffer.getString().should.equal('\n')
      two.isInOutline.should.be.ok
      three.isInOutline.should.be.ok
      four.isInOutline.should.be.ok
      five.isInOutline.should.not.be.ok
      six.isInOutline.should.not.be.ok

    it 'should replace range with items (in plain text)', ->
      serialized = editor.serializeRange(4, 10, type: 'text/plain')
      deserializedItems = editor.deserializeItems(serialized, type: 'text/plain')
      editor.replaceRangeWithItems(4, 10, deserializedItems)
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')
      deserializedItems[0].depth.should.equal(2)
      deserializedItems[0].isInOutline.should.be.ok
      deserializedItems[0].firstChild.depth.should.equal(3)
      deserializedItems[0].lastChild.depth.should.equal(3)
      two.isInOutline.should.not.be.ok

    it 'should replace full range with string', ->
      two.removeFromParent()
      five.removeFromParent()
      itemBuffer.getString().should.equal('one\n')
      editor.replaceRangeWithString(0, 3, 'a')
      itemBuffer.getString().should.equal('a\n')

    it 'should append folded items of replace item to preview item', ->
      editor.setCollapsed([two, five])
      editor.replaceRangeWithString(7, 1, '')
      itemBuffer.getString().should.equal('one\ntwofive\n')
      editor.setExpanded(root.descendants)
      itemBuffer.getString().should.equal('one\ntwofive\nthree\nfour\nsix\n')

    it 'should replace trailing hidden with visible ancestor', ->
      editor.setCollapsed([two])
      editor.moveSelectionToRange(7, 8)
      editor.replaceRangeWithString(7, 1, '')

      editor.setExpanded([two])
      itemBuffer.getString().should.equal('one\ntwofive\nsix\n')

      editor.setCollapsed([two])
      editor.moveSelectionToRange(11, 12)
      editor.replaceRangeWithString(11, 1, '')

      editor.setExpanded([two])
      itemBuffer.getString().should.equal('one\ntwofive\n')

    it 'should replace range before last character in focused view', ->
      editor.focusedItem = two
      editor.replaceRangeWithString(14, 0, 'a\nb')
      itemBuffer.getString().should.equal('two\nthree\nfoura\nb\n')
      editor.hoistedItem = root
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfoura\nb\nfive\nsix\n')

    it 'should replace range after last character in focused view', ->
      editor.focusedItem = two
      editor.replaceRangeWithString(15, 0, 'a\nb')
      itemBuffer.getString().should.equal('two\nthree\nfour\na\nb\n')
      editor.hoistedItem = root
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\na\nb\nfive\nsix\n')

    it 'should replace full item range of focused item with children', ->
      editor.focusedItem = two
      editor.replaceRangeWithString(0, 4, 'a')
      itemBuffer.getString().should.equal('athree\nfour\n')

    describe 'Trailing newline', ->

      it 'should insert trailing newline after inserting newline', ->
        editor.replaceRangeWithString(0, itemBuffer.getLength(), 'test')
        editor.nativeEditor.text.should.equal(itemBuffer.getString())
        itemBuffer.getString().should.equal('test\n')

      it 'should insert trailing newline after inserting newline', ->
        editor.replaceRangeWithString(0, itemBuffer.getLength(), '\n')
        editor.nativeEditor.text.should.equal(itemBuffer.getString())
        itemBuffer.getString().should.equal('\n\n')

      it 'should ignore replace of last newline', ->
        editor.replaceRangeWithString(0, itemBuffer.getLength(), '\n')
        editor.replaceRangeWithString(0, itemBuffer.getLength(), '\n')
        editor.nativeEditor.text.should.equal(itemBuffer.getString())
        itemBuffer.getString().should.equal('\n\n')

  describe 'Organize', ->

    describe 'Move Lines', ->

      it 'should move lines up', ->
        editor.setCollapsed(five)
        editor.moveSelectionToItems(five, 1)
        editor.moveLinesUp()
        editor.isFiltered(five).should.be.ok
        four.parent.should.equal(five)
        six.parent.should.equal(five)
        five.parent.should.equal(one)
        five.previousSibling.should.equal(two)
        editor.selection.toString().should.eql('15,15')
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfive\nfour\n')

      it 'should move fully selected lines up', ->
        editor.moveSelectionToItems(five, 0, six, 0)
        editor.moveLinesUp()
        four.parent.should.equal(five)
        six.parent.should.equal(five)
        five.parent.should.equal(one)
        five.previousSibling.should.equal(two)
        editor.selection.toString().should.eql('14,19')
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfive\nfour\nsix\n')

      it 'should move lines up anchoring to previous visible item', ->
        editor.moveSelectionToItems(one, 0, six, 0)
        editor.moveLinesLeft()
        editor.moveLinesLeft()
        editor.itemPathFilter = 'not w' # hide two
        editor.moveSelectionToItems(four)
        editor.moveLinesUp()
        editor.itemPathFilter = ''
        itemBuffer.getString().should.equal('one\nfour\ntwo\nthree\nfive\nsix\n')

      it 'should move lines up anchoring to previous visible item (case 2)', ->
        editor.setCollapsed(two)
        editor.moveSelectionToItems(six)
        editor.moveLinesUp()
        itemBuffer.getString().should.equal('one\ntwo\nsix\nfive\n')
        editor.setExpanded(two)
        itemBuffer.getString().should.equal('one\ntwo\nsix\nthree\nfour\nfive\n')

      it 'should move lines down', ->
        editor.setCollapsed([two])
        editor.moveSelectionToItems(two)
        editor.moveLinesDown()
        editor.isFiltered(two).should.be.ok
        six.parent.should.equal(two)
        five.parent.should.equal(one)
        two.previousSibling.should.equal(five)
        editor.selection.toString().should.eql('9,9')
        itemBuffer.getString().should.equal('one\nfive\ntwo\nsix\n')

      it 'should move lines down past hidden items', ->
        editor.setCollapsed([two, five])
        editor.moveSelectionToItems(two)
        editor.moveLinesDown()
        six.parent.should.equal(five)
        five.parent.should.equal(one)
        two.previousSibling.should.equal(five)
        editor.selection.toString().should.eql('9,9')
        itemBuffer.getString().should.equal('one\nfive\ntwo\n')

      it 'should move lines down past collapsed children items', ->
        editor.setCollapsed(five)
        editor.moveSelectionToItems(two, 0, five, 0)
        editor.moveLinesDown()
        six.parent.should.equal(five)
        five.parent.should.equal(one)
        two.previousSibling.should.equal(five)
        editor.selection.toString().should.eql('9,24')
        itemBuffer.getString().should.equal('one\nfive\ntwo\nthree\nfour\n')

      it 'should move lines down and expand if capture children', ->
        three.removeFromParent()
        four.removeFromParent()
        editor.moveSelectionToItems(two)
        editor.moveLinesDown()
        six.parent.should.equal(two)
        two.previousSibling.should.equal(five)
        editor.isExpanded(two).should.equal(true)
        editor.selection.toString().should.eql('9,9')
        itemBuffer.getString().should.equal('one\nfive\ntwo\nsix\n')

      it 'should not move lines down out of hoisted item', ->
        editor.hoistedItem = two
        editor.moveSelectionToItems(three, 1)
        editor.moveLinesDown()
        editor.moveLinesDown()
        three.previousSibling.should.equal(four)

      it 'should not move lines down out of focused item', ->
        editor.focusedItem = two
        editor.moveSelectionToItems(three, 1)
        editor.moveLinesDown()
        editor.isDisplayed(three).should.be.true
        editor.moveLinesDown()
        editor.isDisplayed(three).should.be.true
        three.previousSibling.should.equal(four)

      it 'should not move lines up out of focused item', ->
        editor.focusedItem = five
        editor.moveSelectionToItems(six, 1)
        editor.moveLinesUp()
        editor.isDisplayed(six).should.be.true
        editor.moveLinesUp()
        editor.isDisplayed(six).should.be.true
        six.nextItem.should.equal(five)

      it 'should move lines down without changing indent level', ->
        two.removeFromParent()
        five.removeFromParent()
        root.appendChildren(four)
        three.indent = 3
        outline.insertItemsBefore(three, four)
        editor.setExpanded(one)
        editor.moveSelectionToItems(one, 1)
        editor.moveLinesDown()
        one.indent.should.equal(1)
        itemBuffer.getString().should.equal('three\none\nfour\n')

      it 'should move lines right', ->
        editor.setCollapsed(five)
        editor.moveSelectionToItems(five, 1)
        editor.moveLinesRight()
        six.parent.should.equal(five)
        five.parent.should.equal(two)
        five.previousSibling.should.equal(four)
        five.firstChild.should.equal(six)
        editor.selection.toString().should.eql('20,20')
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\n')

      it 'should move lines right special case', ->
        each.removeFromParent() for each in outline.root.descendants
        one.indent = 1
        two.indent = 3
        three.indent = 2
        four.indent = 1
        outline.insertItemsBefore([one, two, three, four])
        editor.moveSelectionToItems(one, 1, two, 1)
        editor.moveLinesRight()
        root.firstChild.should.equal(one)

      it 'should undo move lines right', ->
        three.depth.should.equal(3)
        editor.moveSelectionToItems(three, 0)
        editor.moveLinesRight()
        three.depth.should.equal(4)
        editor.outline.undoManager.undo()
        three.depth.should.equal(3)

      it 'should undo move lines right case 2', ->
        three.removeFromParent()
        four.removeFromParent()
        five.removeFromParent()
        editor.moveSelectionToItems(one, 0, two, 3)
        one.depth.should.equal(1)
        editor.moveLinesRight()
        one.depth.should.equal(2)
        two.indent.should.equal(1)
        two.parent.should.equal(one)
        editor.outline.undoManager.undo()
        two.parent.should.equal(one)
        one.depth.should.equal(1)
        two.indent.should.equal(1)

      it 'should move lines left', ->
        editor.setCollapsed(five)
        editor.moveSelectionToItems(five)
        editor.moveLinesLeft()
        six.parent.should.equal(five)
        six.indent.should.equal(1)
        five.parent.should.equal(root)
        five.previousSibling.should.equal(one)
        editor.selection.toString().should.eql('19,19')
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\n')

      it 'should restrict move lines left to hoisted region', ->
        editor.hoistedItem = two
        editor.moveSelectionToItems(three, 1)
        editor.moveLinesLeft()
        editor.selection.toString().should.eql('1,1')
        itemBuffer.getString().should.equal('three\nfour\n')

      it 'should restrict move lines left to maintain structure of hidden items', ->
        editor.setCollapsed(five)
        editor.moveSelectionToItems(one, 0, five, 4)
        editor.moveLinesLeft()
        editor.moveLinesLeft()
        three.depth.should.equal(1)
        four.depth.should.equal(1)
        five.depth.should.equal(1)
        six.depth.should.equal(2)
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\n')

      it 'should restrict move lines up to hoisted region', ->
        editor.hoistedItem = two
        editor.moveSelectionToItems(three, 1)
        editor.moveLinesUp()
        editor.selection.toString().should.eql('1,1')
        itemBuffer.getString().should.equal('three\nfour\n')

      it 'should restrict move lines down to hoisted region', ->
        editor.hoistedItem = two
        editor.moveSelectionToItems(four, 1)
        editor.moveLinesDown()
        editor.selection.toString().should.eql('7,7')
        itemBuffer.getString().should.equal('three\nfour\n')

    describe 'Group Lines', ->

      it 'should group lines', ->
        editor.moveSelectionToItems(three, 1, four, 2)
        editor.groupLines()
        itemBuffer.getString().should.equal('one\ntwo\n\nthree\nfour\nfive\nsix\n')

    describe 'Duplicate Lines', ->

      it 'should duplicate lines', ->
        editor.moveSelectionToItems(three, 1, four, 2)
        editor.duplicateLines()
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nthree\nfour\nfive\nsix\n')

      it 'should duplicate collapsed lines', ->
        editor.setCollapsed(two)
        editor.moveSelectionToItems(two)
        editor.duplicateLines()
        itemBuffer.getString().should.equal('one\ntwo\ntwo\nfive\nsix\n')

    describe 'Delete Lines', ->

      it 'should delete lines', ->
        editor.moveSelectionToItems(five, 1)
        editor.deleteLines()
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nsix\n')

      it 'should delete collapsed lines', ->
        editor.setCollapsed(five)
        editor.moveSelectionToItems(five, 1)
        editor.deleteLines()
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\n')
        five.isInOutline.should.be.false
        six.isInOutline.should.be.false
        editor.outline.undoManager.undo()
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\n')
        five.isInOutline.should.be.true
        six.isInOutline.should.be.true

    describe 'Move Branches', ->

      it 'should move branches up', ->
        editor.setCollapsed([two, five])
        editor.moveSelectionToItems(five)
        editor.moveBranchesUp()
        one.firstChild.should.equal(five)
        one.lastChild.should.equal(two)
        itemBuffer.getString().should.equal('one\nfive\ntwo\n')
        editor.moveBranchesUp()
        one.firstChild.should.equal(two)
        root.firstChild.should.equal(five)
        editor.moveBranchesUp() # should do nothinbg

      it 'should move fully selected branches up', ->
        editor.moveSelectionToItems(three, 0, four, 0)
        editor.moveBranchesUp()
        editor.selection.toString().should.eql('4,10')

      it 'should move branches down', ->
        editor.setExpanded(one)
        editor.moveSelectionToItems(two)
        editor.moveBranchesDown()
        one.firstChild.should.equal(five)
        one.lastChild.should.equal(five)
        five.firstChild.should.equal(two)
        editor.moveBranchesDown()
        five.lastChild.should.equal(two)
        editor.moveBranchesDown() # should do nothinbg

      it 'should move items left', ->
        editor.setExpanded(one)
        editor.moveSelectionToItems(two)
        editor.moveBranchesLeft()
        one.firstChild.should.equal(five)
        one.nextSibling.should.equal(two)
        editor.moveBranchesLeft() # should do nothing
        one.nextSibling.should.equal(two)

      it 'should move items left with prev sibling children selected', ->
        editor.setExpanded(one)
        editor.setExpanded(two)
        editor.moveSelectionToItems(four, undefined, five)
        editor.moveBranchesLeft()
        two.nextSibling.should.equal(four)
        four.nextSibling.should.equal(five)

      it 'should move items right', ->
        editor.setExpanded(one)
        editor.setExpanded(two)
        editor.moveSelectionToItems(four)
        editor.moveBranchesRight()
        three.firstChild.should.equal(four)

      it 'should move to same location as current without crash', ->
        editor.moveBranches([one], one.parent, one)

      it 'should move to same location as current without crash', ->
        editor.moveBranches([one], one.parent)

      xit 'should join items', ->
        editor.setExpanded(one)
        editor.moveSelectionToItems(one)
        editor.joinItems()
        one.bodyString.should.equal('one two')
        editor.selection.headItem.should.equal(one)
        editor.selection.headOffset.should.equal(3)
        one.firstChild.should.equal(three)
        one.firstChild.nextSibling.should.equal(four)

      xit 'should join items and undo', ->
        editor.setExpanded(one)
        editor.moveSelectionToItems(one)
        editor.joinItems()
        editor.outline.undoManager.undo()
        two.firstChild.should.equal(three)
        two.lastChild.should.equal(four)

    describe 'Group', ->

      it 'should group selected branches into new branch', ->
        editor.moveSelectionToItems(two, 1, five, 0)
        editor.groupBranches()
        editor.selection.toString().should.eql('4,4')
        itemBuffer.getString().should.equal('one\n\ntwo\nthree\nfour\nfive\nsix\n')

    describe 'Duplicate', ->

      it 'should duplicate selected branches', ->
        editor.moveSelectionToItems(five, 0, five, 2)
        editor.duplicateBranches()
        editor.selection.toString().should.eql('28,30')
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\nfive\nsix\n')

    describe 'Promote Children', ->

      it 'should promote child branches', ->
        editor.moveSelectionToItems(two)
        editor.promoteChildBranches()
        editor.selection.toString().should.eql('4,4')
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

    describe 'Demote Trailing Siblings', ->

      it 'should demote trailing sibling branches', ->
        editor.moveSelectionToItems(two)
        editor.demoteTrailingSiblingBranches()
        editor.selection.toString().should.eql('4,4')
        itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

    describe 'Insert Locations', ->

      it 'should calculate insert before location in unfiltered view', ->
        editor._getInsertBeforeItemFromInsertAfterItemAtDepth(five, one.depth).should.equal(six)

      it 'should calculate insert before location in filtered view (case 1)', ->
        child = outline.createItem('child')
        two.appendChildren(child)
        editor.forceHidden([three, child])
        editor._getInsertBeforeItemFromInsertAfterItemAtDepth(two, one.depth).should.equal(four)

      it 'should calculate insert before location in filtered view (case 2)', ->
        child = outline.createItem('child')
        two.appendChildren(child)
        editor.forceHidden([three, child])
        editor._getInsertBeforeItemFromInsertAfterItemAtDepth(four, one.depth).should.equal(five)

      it 'should calculate insert before location in filtered view (case 3)', ->
        child = outline.createItem('child')
        two.appendChildren(child)
        editor.forceHidden([three, child])
        editor._getInsertBeforeItemFromInsertAfterItemAtDepth(four, one.depth).should.equal(five)
        editor._getInsertBeforeItemFromInsertAfterItemAtDepth(four, three.depth).should.equal(child)

      it 'should calculate insert before location in filtered view (case 4)', ->
        editor.forceHidden([four, five, six])
        editor._getInsertBeforeItemFromInsertAfterItemAtDepth(three, three.depth - 1).should.equal(five)

  describe 'Text Attributes', ->

    it 'should toggle formatting', ->
      editor.moveSelectionToItems(one, 0, one, 2)
      editor.toggleTextAttribute('b')
      one.bodyHTMLString.should.equal('<b>on</b>e')
      editor.toggleTextAttribute('b')
      one.bodyHTMLString.should.equal('one')

    xit 'should toggle typing formatting tags if collapsed selection', ->
      one.bodyText = ''
      editor.moveSelectionToItems(one, 0)
      editor.toggleTextAttribute('B')
      editor.insertText('hello')
      one.bodyHTMLString.should.equal('<b>hello</b>')
      editor.toggleTextAttribute('B')
      editor.insertText('world')
      one.bodyHTMLString.should.equal('<b>hello</b>world')

  describe 'Commands', ->

    it 'should backspace', ->
      editor.moveSelectionToItems(one, 2, one, 3)
      editor.backspace()
      one.bodyString.should.equal('on')
      editor.backspace()
      one.bodyString.should.equal('o')

    it 'should backspace to delete all', ->
      editor.moveSelectionToItems(one, 0, six, 3)
      editor.backspace()
      editor.itemBuffer.getString().should.equal('\n')

    it 'should toggle attribute of selected items', ->
      editor.moveSelectionToItems(one, 0, three, 0)
      editor.toggleAttribute('moose', 'goose')
      one.getAttribute('moose').should.equal('goose')
      two.getAttribute('moose').should.equal('goose')
      three.hasAttribute('moose').should.be.false
      editor.toggleAttribute('moose', 'goose')
      one.hasAttribute('moose').should.be.false
      two.hasAttribute('moose').should.be.false
      three.hasAttribute('moose').should.be.false

    describe 'Events', ->

      it 'should not generate outline beginEditing events when hoisting item', ->
        didBeginChanges = false
        subscription = outline.onDidBeginChanges ->
          didBeginChanges = true
        editor.hoistedItem = two
        subscription.dispose()
        didBeginChanges.should.equal(false)

      it 'should not generate outline beginEditing events when changing filter', ->
        didBeginChanges = false
        subscription = outline.onDidBeginChanges ->
          didBeginChanges = true
        editor.itemPathFilter = 'boo!'
        subscription.dispose()
        didBeginChanges.should.equal(false)

    describe 'Undo', ->

      it 'should restore selection on undo/redo', ->
        editor.moveSelectionToRange(0, 1)
        editor.replaceRangeWithString(0, 1, '')
        editor.outline.undoManager.undo()
        editor.selection.toString().should.equal('0,1')
        editor.outline.undoManager.redo()
        editor.selection.toString().should.equal('0,0')

      it 'should not crash when restore null selection on undo/redo', ->
        editor.moveSelectionToRange(0, 1)
        one.removeFromParent()
        editor.outline.undoManager.undo()
        editor.selection.toString().should.equal('0,1')
        editor.outline.undoManager.redo()
        editor.selection.toString().should.equal('0,0')

      it 'should not crash when select all and delete and undo in this case', ->
        editor.replaceRangeWithString(0, editor.textLength, '\ta\nb\nc')
        editor.moveSelectionToRange(0, editor.textLength)

        editor.replaceRangeWithString(0, editor.textLength, '')
        editor.textLength.should.equal(1)
        editor.outline.undoManager.undo()
        editor.getTextInRange(0, editor.textLength).should.equal('\ta\nb\nc\n')
        editor.outline.undoManager.redo()
        editor.getTextInRange(0, editor.textLength).should.equal('\n')

  describe 'Geometry', ->

    it 'should get rect for range', ->
      editor.getRectForRange(0, 0).should.eql(x: 0, y: 0, width: 100, height: 10)
      editor.getRectForRange(0, 3).should.eql(x: 0, y: 0, width: 100, height: 10)
      editor.getRectForRange(0, 4).should.eql(x: 0, y: 0, width: 100, height: 20)
      editor.getRectForRange(4, 2).should.eql(x: 0, y: 10, width: 100, height: 10)

  describe 'Native Editor Updates', ->

    beforeEach ->
      simple.mock(nativeEditor, '_setSelectedRange')
      simple.mock(nativeEditor, '_setScrollPoint')
      simple.mock(nativeEditor, 'invalidateAttributesForCharacterRange')
      simple.mock(nativeEditor, 'replaceCharactersInRangeWithString')
      simple.mock(nativeEditor, '_didEndEditing')

    it 'should minimally update native editor when replacing range', ->
      editor.moveSelectionToRange(4, 4)
      editor.replaceRangeWithString(4, 0, 'a')
      nativeEditor.replaceCharactersInRangeWithString.callCount.should.equal(1)
      nativeEditor.replaceCharactersInRangeWithString.lastCall.args[0].should.eql(location: 4, length: 0)
      nativeEditor.replaceCharactersInRangeWithString.lastCall.args[1].should.eql('a')
      nativeEditor._setScrollPoint.callCount.should.equal(2)
      nativeEditor._setSelectedRange.callCount.should.equal(2)
      nativeEditor._setSelectedRange.lastCall.args[0].should.eql(location: 5, length: 0)
      nativeEditor._didEndEditing.callCount.should.equal(1)

    it 'should minimally update native editor when insert newline', ->
      editor.moveSelectionToRange(2, 2)
      editor.insertNewline()
      nativeEditor.replaceCharactersInRangeWithString.callCount.should.equal(2)
      nativeEditor._setScrollPoint.callCount.should.equal(2)
      nativeEditor._setSelectedRange.callCount.should.equal(2)
      nativeEditor._didEndEditing.callCount.should.equal(3)

    it 'should minimally update native editor when insert item', ->
      editor.moveSelectionToRange(2, 2)
      editor.insertItem('hello')
      nativeEditor.replaceCharactersInRangeWithString.callCount.should.equal(1)
      nativeEditor._setScrollPoint.callCount.should.equal(2)
      nativeEditor._setSelectedRange.callCount.should.equal(2)
      nativeEditor._didEndEditing.callCount.should.equal(2)

  describe 'Performance', ->

    it 'should style 10,000 items', ->
      lines = []
      for i in [0..(5000)]
        lines.push('hello world')
      lines = lines.join('\n')

      editor.replaceRangeWithString(0, 0, lines)
      for each in editor.outline.root.descendants
        if each.bodyString.length > 5
          each.addBodyAttributeInRange('b', {}, 1, 2)
          each.addBodyAttributeInRange('i', {}, 2, 2)

      ids = (each.id for each in editor.outline.root.descendants)

      console.profile?('Compute Style Metadata')
      console.time('Compute Style Metadata')
      itemBuffer.updateOutline ->
        editor.getComputedStyleMetadataForItemIDs(ids)
      console.timeEnd('Compute Style Metadata')
      console.profileEnd?()
