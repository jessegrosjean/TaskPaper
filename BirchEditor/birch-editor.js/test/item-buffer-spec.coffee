loadOutlineFixture = require './load-outline-fixture'
{ Outline, Mutation }  = require 'birch-outline'
ItemBuffer = require '../src/item-buffer'
should = require('chai').should()

describe 'ItemBuffer', ->
  [itemBuffer, bufferSubscription, itemBufferDidChangeExpects, outline, outlineSubscription, outlineDidChangeExpects, root, one, two, three, four, five, six] = []

  beforeEach ->
    {outline, root, one, two, three, four, five, six} = loadOutlineFixture()
    itemBuffer = new ItemBuffer(outline)
    itemBuffer.hoistedItem = outline.root
    outlineSubscription = outline.onDidChange (mutation) ->
      if outlineDidChangeExpects
        exp = outlineDidChangeExpects.shift()
        exp(mutation)

    bufferSubscription = itemBuffer.onDidChange (e) ->
      if itemBufferDidChangeExpects
        exp = itemBufferDidChangeExpects.shift()
        exp(e)

  afterEach ->
    if outlineDidChangeExpects
      outlineDidChangeExpects.length.should.equal(0)
      outlineDidChangeExpects = null
    outlineSubscription.dispose()
    if itemBufferDidChangeExpects
      itemBufferDidChangeExpects.length.should.equal(0)
      itemBufferDidChangeExpects = null
    bufferSubscription.dispose()
    outline.retainCount.should.equal(1)
    outline.destroy()
    outline.retainCount.should.equal(0)
    outline.isRetained().should.equal(false)
    Outline.outlines.length.should.equal(0)

  it 'can be fully emptied', ->
    one.removeFromParent()
    itemBuffer.getString().should.equal('')
    itemBuffer.getLineCount().should.equal(0)
    itemBuffer.getLength().should.equal(0)
    should.equal(outline.root.firstChild, null)

  it 'should map between locations and item offsets', ->
    itemBuffer.getLocationForItemOffset(one, 0).should.equal(0)
    itemBuffer.getLocationForItemOffset(six, 1).should.equal(25)
    itemBuffer.getLocationForItemOffset(six, 4).should.equal(28)

    itemBuffer.getItemOffsetForLocation(0).should.eql
      item: one
      offset: 0

    itemBuffer.getItemOffsetForLocation(28).should.eql
      item: six
      offset: 4

    itemBuffer.setExpandedState([two, five], false)

    itemBuffer.getItemOffsetForLocation(8).should.eql
      item: five
      offset: 0

    itemBuffer.getItemOffsetForLocation(13).should.eql
      item: six
      offset: 4

  describe 'Hoisted Item', ->

    it 'should hoist root by default', ->
      itemBuffer.hoistedItem.should.equal(root)
      itemBuffer.isDisplayed(root).should.be.false

    it 'should make children of hoisted item visible', ->
      itemBuffer.hoistedItem = two
      itemBuffer.isDisplayed(itemBuffer.hoistedItem).should.be.false
      itemBuffer.isDisplayed(three).should.be.true
      itemBuffer.isDisplayed(four).should.be.true
      itemBuffer.getString().should.equal('three\nfour\n')

    it 'should hoist item with no children', ->
      itemBuffer.hoistedItem = three
      itemBuffer.getString().should.equal('')

    it 'should hoist item with no children and insert children when text inserted into buffer', ->
      itemBuffer.hoistedItem = three
      itemBuffer.getString().should.equal('')
      itemBuffer.beginUpdatingOutline()
      itemBuffer.replaceRange(0, 0, 'Hello!')
      itemBuffer.endUpdatingOutline()
      itemBuffer.getString().should.equal('Hello!\n')
      three.firstChild.bodyString.should.equal('Hello!')

    it 'should not update item index when items are added outide hoisted item', ->
      itemBuffer.hoistedItem = two
      outline.root.appendChildren(outline.createItem('not me!'))
      itemBuffer.getString().should.equal('three\nfour\n')

    it 'should handle deletion of hoisted item', ->
      itemBuffer.hoistedItem = two
      two.removeFromParent()
      itemBuffer.hoistedItem.should.equal(root)
      itemBuffer.getString().should.equal('one\nfive\nsix\n')

  describe 'Focus Item', ->

    it 'should focus null by default', ->
      should.equal(itemBuffer.focusedItem, null)

    it 'should set focus item', ->
      itemBuffer.setExpandedState([one, two], false)
      itemBuffer.isExpanded(two).should.not.be.ok
      itemBuffer.focusedItem = two
      itemBuffer.hoistedItem.should.equal(one)
      itemBuffer.focusedItem.should.equal(two)
      itemBuffer.isExpanded(two).should.be.ok
      itemBuffer.isDisplayed(two).should.be.ok
      itemBuffer.isDisplayed(three).should.be.ok
      itemBuffer.isDisplayed(four).should.be.ok
      itemBuffer.isDisplayed(five).should.not.be.ok
      itemBuffer.focusedItem = null
      should.equal(itemBuffer.focusedItem, null)
      itemBuffer.hoistedItem.should.equal(root)
      itemBuffer.isExpanded(two).should.not.be.ok
      itemBuffer.itemPathFilter.should.equal('')
      itemBuffer.isDisplayed(three).should.not.be.ok
      itemBuffer.isDisplayed(four).should.not.be.ok

    it 'should clear focus item when hoisting', ->
      itemBuffer.focusedItem = one
      itemBuffer.hoistedItem = root
      itemBuffer.itemPathFilter.should.equal('')
      should.equal(itemBuffer.focusedItem, null)

    it 'should handle deletion of focused item', ->
      itemBuffer.focusedItem = two
      two.removeFromParent()
      itemBuffer.hoistedItem.should.equal(one)
      should.equal(itemBuffer.focusedItem, null)
      itemBuffer.getString().should.equal('')
      itemBuffer.updateOutline ->
        itemBuffer.insertString(0, 'hello')
      itemBuffer.getString().should.equal('hello\n')

  describe 'Expand & Collapse Items', ->

    it 'items should be expanded by default', ->
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')
      itemBuffer.isExpanded(one).should.be.ok

    it 'should hide children when item is collapsed', ->
      itemBufferDidChangeExpects = [
        (e) ->
          e.location.should.equal(4)
          e.replacedLength.should.equal(24)
          e.insertedString.should.equal('')
      ]

      itemBuffer.setExpandedState([one], false)
      itemBuffer.isExpanded(one).should.be.false
      itemBuffer.isDisplayed(two).should.be.false
      itemBuffer.isDisplayed(five).should.be.false
      itemBuffer.getString().should.equal('one\n')
      itemBuffer.getLength().should.equal(4)

    it 'should show children when visible item is expanded', ->
      itemBuffer.setExpandedState([one], false)

      itemBufferDidChangeExpects = [
        (e) ->
          e.location.should.equal(4)
          e.replacedLength.should.equal(0)
          e.insertedString.should.equal('two\nthree\nfour\nfive\nsix\n')
      ]

      itemBuffer.setExpandedState([one], true)
      itemBuffer.isExpanded(one).should.be.true
      itemBuffer.isDisplayed(two).should.be.true
      itemBuffer.isDisplayed(five).should.be.true
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

    it 'should expand mutliple items at once', ->
      itemBuffer.setExpandedState([one, two, five], false)
      itemBuffer.setExpandedState([one, two, five], true)
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

    it 'should allow insert in trailing folded range', ->
      itemBuffer.setExpandedState([one], false)
      itemBuffer.beginUpdatingOutline()
      itemBuffer.replaceRange(4, 0, 'hello')
      itemBuffer.getString().should.equal('one\nhello\n')
      itemBuffer.endUpdatingOutline()
      one.firstChild.should.equal(two)

    it 'should insert into folded, changing to filtered', ->
      itemBuffer.setExpandedState([two], false)
      two.appendChildren(six)
      itemBuffer.isCollapsed(two).should.be.ok
      itemBuffer.forceDisplayed(six)
      itemBuffer.isFiltered(two).should.be.ok
      itemBuffer.getString().should.equal('one\ntwo\nsix\nfive\n')

    it 'should manually hide and show items', ->
      itemBuffer.forceHidden([one, three, five])
      itemBuffer.getString().should.equal('two\nfour\nsix\n')
      itemBuffer.forceDisplayed(three)
      itemBuffer.getString().should.equal('two\nthree\nfour\nsix\n')
      itemBuffer.forceHidden([one, two, three, four, five, six])
      itemBuffer.getString().should.equal('')
      itemBuffer.forceDisplayed(six, true)
      itemBuffer.getString().should.equal('one\nfive\nsix\n')

    it 'should expand item with filtered children correctly', ->
      itemBuffer.itemPathFilter = 'four'
      itemBuffer.getString().should.equal('one\ntwo\nfour\n')
      itemBuffer.setExpandedState([one], true)
      itemBuffer.getString().should.equal('one\ntwo\nthree\nfour\nfive\nsix\n')

  describe 'Filter Items', ->

    it 'should set/get filter', ->
      itemBuffer.itemPathFilter.should.equal('')
      itemBuffer.itemPathFilter = 'hello world'
      itemBuffer.itemPathFilter.should.equal('hello world')

    it 'should filter itemBuffer to show items (and ancestors) matching filter', ->
      itemBuffer.itemPathFilter = 'two'
      itemBuffer.isDisplayed(one).should.be.ok
      itemBuffer.isFiltered(one).should.be.ok
      itemBuffer.isExpanded(one).should.not.be.ok
      itemBuffer.isDisplayed(two).should.be.ok
      itemBuffer.isExpanded(two).should.not.be.ok
      itemBuffer.isDisplayed(three).should.not.be.ok
      itemBuffer.isDisplayed(five).should.not.be.ok
      itemBuffer.itemPathFilter = null
      itemBuffer.isDisplayed(one).should.be.ok
      itemBuffer.isDisplayed(two).should.be.ok
      itemBuffer.isDisplayed(three).should.be.ok
      itemBuffer.isDisplayed(five).should.be.ok

    it 'should expand to show filter and restore original expanded after filter', ->
      itemBuffer.setExpandedState([two], false)
      itemBuffer.itemPathFilter = 'three or five'
      itemBuffer.isDisplayed(one).should.be.ok
      itemBuffer.isDisplayed(two).should.be.ok
      itemBuffer.isFiltered(two).should.be.ok
      itemBuffer.isExpanded(two).should.not.be.ok
      itemBuffer.isDisplayed(three).should.be.ok
      itemBuffer.isDisplayed(four).should.not.be.ok
      itemBuffer.isDisplayed(five).should.be.ok
      itemBuffer.isCollapsed(five).should.be.ok
      itemBuffer.isDisplayed(six).should.not.be.ok
      itemBuffer.itemPathFilter = ''
      itemBuffer.isDisplayed(one).should.be.ok
      itemBuffer.isDisplayed(two).should.be.ok
      itemBuffer.isExpanded(two).should.not.be.ok
      itemBuffer.isDisplayed(three).should.not.be.ok
      itemBuffer.isDisplayed(four).should.not.be.ok
      itemBuffer.isDisplayed(five).should.be.ok
      itemBuffer.isCollapsed(five).should.not.be.ok
      itemBuffer.isDisplayed(six).should.be.ok

    it 'should add new inserted items to filter results', ->
      itemBuffer.itemPathFilter = 'three'
      itemBuffer.beginUpdatingOutline()
      itemBuffer.replaceRange(11, 0, '\n')
      itemBuffer.endUpdatingOutline()
      itemBuffer.getString().should.equal('one\ntwo\nthr\nee\n')
      itemBuffer.itemPathFilter = ''
      itemBuffer.getString().should.equal('one\ntwo\nthr\nee\nfour\nfive\nsix\n')

  describe 'Outline to Index', ->

    it 'maps items to item spans', ->
      itemBuffer.toString().should.equal('(one\n/1)(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'can change the item that is mapped', ->
      itemBuffer.hoistedItem = two
      itemBuffer.toString().should.equal('(three\n/3)(four\n/4)')

    it 'updates index span when item text changes', ->
      one.bodyString = 'moose'
      one.replaceBodyRange(5, 0, 's')
      one.appendBody('!')
      itemBuffer.toString().should.equal('(mooses!\n/1)(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'adds index spans when item is added to outline', ->
      newItem = outline.createItem('new')
      newItem.id = 'a'
      two.appendChildren(newItem)
      itemBuffer.toString().should.equal('(one\n/1)(two\n/2)(three\n/3)(four\n/4)(new\n/a)(five\n/5)(six\n/6)')

      newItem = outline.createItem('new')
      newItem.id = 'b'
      newItemChild = outline.createItem('new child')
      newItemChild.id = 'bchild'
      newItem.appendChildren(newItemChild)
      five.appendChildren(newItem)
      itemBuffer.toString().should.equal('(one\n/1)(two\n/2)(three\n/3)(four\n/4)(new\n/a)(five\n/5)(six\n/6)(new\n/b)(new child\n/bchild)')

    it 'removes index spans when item is removed from outline', ->
      two.removeFromParent()
      itemBuffer.toString().should.equal('(one\n/1)(five\n/5)(six\n/6)')
      six.removeFromParent()
      itemBuffer.toString().should.equal('(one\n/1)(five\n/5)')
      five.removeFromParent()
      itemBuffer.toString().should.equal('(one\n/1)')
      one.removeFromParent()
      itemBuffer.toString().should.equal('')

  describe 'Index to Outline', ->

    it 'update item text when span text changes from start', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.deleteRange(0, 1)
      itemBuffer.endUpdatingOutline()
      itemBuffer.toString().should.equal('(ne\n/1)(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'update item text when span text changes from middle', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.deleteRange(1, 1)
      itemBuffer.endUpdatingOutline()
      itemBuffer.toString().should.equal('(oe\n/1)(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'update item text when span text changes from end', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.deleteRange(2, 1)
      itemBuffer.endUpdatingOutline()
      itemBuffer.toString().should.equal('(on\n/1)(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'adds item when newline is inserted into index', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.insertString(1, 'z\nz')
      itemBuffer.endUpdatingOutline()
      one.nextItem.id = 'a'
      itemBuffer.toString().should.equal('(oz\n/1)(zne\n/a)(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'adds multiple items when multiple newlines are inserted into index', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.insertString(1, '\nz\nz\n')
      itemBuffer.endUpdatingOutline()
      one.nextItem.id = 'a'
      one.nextItem.nextItem.id = 'b'
      one.nextItem.nextItem.nextItem.id = 'c'
      itemBuffer.toString().should.equal('(o\n/1)(z\n/a)(z\n/b)(ne\n/c)(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'removes item when newline is removed', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.deleteRange(3, 1)
      itemBuffer.endUpdatingOutline()
      itemBuffer.toString().should.equal('(onetwo\n/1)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'removes item when newline is removed, but preserves body attributes', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.deleteRange(13, 1)
      itemBuffer.endUpdatingOutline()
      itemBuffer.toString().should.equal('(one\n/1)(two\n/2)(threefour\n/3)(five\n/5)(six\n/6)')
      three.toString().should.equal('(3) (three)(fo)(u/b:{})(r)')

    it 'remove item in outline when span is removed', ->
      itemBuffer.beginUpdatingOutline()
      itemBuffer.removeSpans(0, 1)
      itemBuffer.endUpdatingOutline()
      itemBuffer.toString().should.equal('(two\n/2)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    it 'add item in outline when span is added', ->
      itemBuffer.beginUpdatingOutline()
      span = itemBuffer.createSpan('new')
      itemBuffer.insertSpans(2, [span])
      itemBuffer.endUpdatingOutline()
      span.item.id = 'NEWID'
      itemBuffer.toString(false).should.equal('(one\n/1)(two\n/2)(new\n/NEWID)(three\n/3)(four\n/4)(five\n/5)(six\n/6)')

    describe 'Generate Index Mutations', ->

      it 'should generate mutation for item body text change', ->
        itemBufferDidChangeExpects = [
          (e) ->
            e.location.should.equal(0)
            e.replacedLength.should.equal(3)
            e.insertedString.should.equal('hello')
          (e) ->
            e.location.should.equal(21)
            e.replacedLength.should.equal(4)
            e.insertedString.should.equal('moose')
        ]
        one.bodyString = 'hello'
        five.bodyString = 'moose'

    describe 'Generate Outline Mutations', ->

      it 'should generate mutation for simple text insert', ->
        outlineDidChangeExpects = [
          (mutation) ->
            mutation.type.should.equal(Mutation.BODY_CHANGED)
            mutation.replacedText.getString().should.equal('')
            mutation.insertedTextLocation.should.equal(0)
            mutation.insertedTextLength.should.equal(5)
        ]
        itemBuffer.beginUpdatingOutline()
        itemBuffer.insertString(0, 'hello')
        itemBuffer.endUpdatingOutline()
        one.bodyString.should.equal('helloone')
        one.depth.should.equal(1)

      it 'should generate mutation for simple text delete', ->
        outlineDidChangeExpects = [
          (mutation) ->
            mutation.type.should.equal(Mutation.BODY_CHANGED)
            mutation.replacedText.getString().should.equal('o')
            mutation.insertedTextLocation.should.equal(0)
            mutation.insertedTextLength.should.equal(0)
        ]
        itemBuffer.beginUpdatingOutline()
        itemBuffer.deleteRange(0, 1)
        itemBuffer.endUpdatingOutline()
        one.bodyString.should.equal('ne')
        one.depth.should.equal(1)

      it 'should generate mutation for simple text replace', ->
        outlineDidChangeExpects = [
          (mutation) ->
            mutation.type.should.equal(Mutation.BODY_CHANGED)
            mutation.replacedText.getString().should.equal('o')
            mutation.insertedTextLocation.should.equal(0)
            mutation.insertedTextLength.should.equal(1)
        ]
        itemBuffer.beginUpdatingOutline()
        itemBuffer.replaceRange(0, 1, 'b')
        itemBuffer.endUpdatingOutline()
        one.bodyString.should.equal('bne')
        one.depth.should.equal(1)

  describe 'Performance', ->

    it 'should load 10,000 items', ->
      lines = []
      for i in [0..(10000)]
        lines.push('hello world')
      lines = lines.join('\n')

      console.profile?('Insert Many Lines')
      console.time('Insert Many Lines')
      itemBuffer.updateOutline ->
        itemBuffer.replaceRange(0, 0, lines)
      console.timeEnd('Insert Many Lines')
      console.profileEnd?()

      console.profile?('To Attributed String')
      console.time('To Attributed String')
      itemBuffer.getAttributedString(0, itemBuffer.getSpanCount())
      console.timeEnd('To Attributed String')
      console.profileEnd?()

    it 'should collapse 10,000 items', ->
      items = []
      for i in [0..(20000)]
        parent = outline.createItem('parent')
        parent.appendChildren(outline.createItem('child'))
        items.push(parent)
      root.appendChildren(items)

      console.profile?('Collapse Many Items')
      console.time('Collapse Many Items')
      itemBuffer.setExpandedState(root.descendants, false)
      console.timeEnd('Collapse Many Items')
      console.profileEnd?()
