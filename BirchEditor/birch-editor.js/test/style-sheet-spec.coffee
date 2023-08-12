loadOutlineFixture = require './load-outline-fixture'
StyleSheet = require '../src/style-sheet'
should = require('chai').should()

describe 'StyleSheet', ->
  [styleSheet, outline, root, one, two, three, four, five, six] = []

  beforeEach ->
    {outline, root, one, two, three, four, five, six} = loadOutlineFixture()
    styleSheet = new StyleSheet()

  it 'should match rule', ->
    should.equal(styleSheet.getStyleKeyForElement(one), null)
    styleSheet = new StyleSheet('item { one: test; }')
    styleSheet.getStyleKeyForElement(one).should.equal('id-0')
    styleSheet.getStyleForKey('id-0').should.eql({ one: 'test' })

  it 'should match rules and combine declarations', ->
    styleSheet = new StyleSheet('item { one: test; }\nitem { two: test; }')
    styleSheet.getStyleKeyForElement(one).should.equal('id-0,id-1')
    styleSheet.getStyleForKey('id-0,id-1').should.eql({ one: 'test', two: 'test' })

  it 'should match rules and combine declarations based on declaration order', ->
    styleSheet = new StyleSheet('item { one: test1; }\nitem { one: test2; }')
    styleSheet.getStyleKeyForElement(one).should.equal('id-0,id-1')
    styleSheet.getStyleForKey('id-0,id-1').should.eql({ one: 'test2' })

  it 'should match inserted rules and combine declarations based on selector specificity order', ->
    one.setAttribute('data-test', '')
    styleSheet = new StyleSheet('item[data-test] { one: test1; }\nitem { one: test2; }')
    styleSheet.getStyleKeyForElement(one).should.equal('id-1,id-0')
    styleSheet.getStyleForKey('id-1,id-0').should.eql({ one: 'test1' })

  it 'should return null style key when no styles matche element', ->
    should.equal(styleSheet.getStyleKeyForElement(null), null)
    should.equal(styleSheet.getStyleKeyForElement(''), null)
    should.equal(styleSheet.getStyleKeyForElement(tagName: 'moose'), null)

  describe 'Matches Selector', ->

    it 'should match type', ->
      StyleSheet.matchesSelector('item', one).should.be.true

    it 'should match attribute', ->
      one.setAttribute('data-test', '')
      StyleSheet.matchesSelector('item[data-test]', one).should.be.true

    it 'should match attribute and equal value', ->
      one.setAttribute('data-test', 'boat')
      StyleSheet.matchesSelector('item[data-test=boat]', one).should.be.true
      StyleSheet.matchesSelector('item[data-test=moose]', one).should.be.false

    it 'should match attribute and start value', ->
      one.setAttribute('data-test', 'boat')
      StyleSheet.matchesSelector('item[data-test^=bo]', one).should.be.true
      StyleSheet.matchesSelector('item[data-test^=at]', one).should.be.false

    it 'should match attribute and contain value', ->
      one.setAttribute('data-test', 'boat')
      StyleSheet.matchesSelector('item[data-test*=bo]', one).should.be.true
      StyleSheet.matchesSelector('item[data-test*=ba]', one).should.be.false

    it 'should match attribute and end value', ->
      one.setAttribute('data-test', 'boat')
      StyleSheet.matchesSelector('item[data-test$=bo]', one).should.be.false
      StyleSheet.matchesSelector('item[data-test$=at]', one).should.be.true
