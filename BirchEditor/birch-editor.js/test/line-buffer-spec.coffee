LineBuffer = require '../src/line-buffer'
{ Outline } = require 'birch-outline'
should = require('chai').should()

describe 'LineBuffer', ->
  [lineBuffer, bufferSubscription, indexDidChangeExpects] = []

  beforeEach ->
    lineBuffer = new LineBuffer()
    bufferSubscription = lineBuffer.onDidChange (e) ->
      if indexDidChangeExpects
        exp = indexDidChangeExpects.shift()
        exp(e)

  afterEach ->
    if indexDidChangeExpects
      indexDidChangeExpects.length.should.equal(0)
      indexDidChangeExpects = null
    bufferSubscription.dispose()
    lineBuffer.destroy()
    Outline.outlines.length.should.equal(0)

  it 'starts empty', ->
    lineBuffer.getLength().should.equal(0)
    lineBuffer.getLineCount().should.equal(0)
    lineBuffer.toString().should.equal('')

  describe 'Insert Text', ->

    it 'creates line for string with no newlines', ->
      indexDidChangeExpects = [
        (e) ->
          e.location.should.equal(0)
          e.replacedLength.should.equal(0)
          e.insertedString.should.equal('one\n')
      ]
      lineBuffer.insertString(0, 'one')
      lineBuffer.toString().should.equal('(one\n)')

    it 'creates lines for string with single newline', ->
      lineBuffer.insertString(0, 'one\ntwo')
      lineBuffer.toString().should.equal('(one\n)(two\n)')

    it 'creates lines for string with multiple newlines', ->
      lineBuffer.insertString(0, 'one\ntwo\n')
      lineBuffer.toString().should.equal('(one\n)(two\n)(\n)')

    it 'inserts just about anywhere and still works', ->
      lineBuffer.insertString(0, 'one\ntwo')

      lineBuffer.insertString(7, '\n')
      lineBuffer.toString().should.equal('(one\n)(two\n)(\n)')

      lineBuffer.insertString(0, '\n')
      lineBuffer.toString().should.equal('(\n)(one\n)(two\n)(\n)')

      lineBuffer.insertString(9, 'a\n')
      lineBuffer.toString().should.equal('(\n)(one\n)(two\n)(a\n)(\n)')

      lineBuffer.insertString(2, '\na\n')
      lineBuffer.toString().should.equal('(\n)(o\n)(a\n)(ne\n)(two\n)(a\n)(\n)')

    it 'insert string before last character in buffer', ->
      lineBuffer.insertString(0, 'one')
      lineBuffer.insertString(3, 'a\nb')
      lineBuffer.toString().should.equal('(onea\n)(b\n)')

    it 'insert string after last character in buffer', ->
      lineBuffer.insertString(0, 'one')
      lineBuffer.insertString(4, 'a\nb')
      lineBuffer.toString().should.equal('(one\n)(a\n)(b\n)')

  describe 'Delete Text', ->

    it 'joins lines when separating \n is deleted', ->
      lineBuffer.insertString(0, 'one\ntwo')
      lineBuffer.deleteRange(3, 1)
      lineBuffer.toString().should.equal('(onetwo\n)')

    it 'joins trailing end line when separating \n is deleted', ->
      lineBuffer.insertString(0, 'one\ntwo\n')
      lineBuffer.deleteRange(7, 1)
      lineBuffer.toString().should.equal('(one\n)(two\n)')

    it 'removes line when its text is fully deleted', ->
      lineBuffer.insertString(0, 'one\ntwo\nthree')
      spanToDelete = lineBuffer.getSpan(1)
      spanNotToDelete = lineBuffer.getSpan(2)
      lineBuffer.deleteRange(4, 4)
      should.equal(spanToDelete.indexParent, null)
      spanNotToDelete.should.equal(lineBuffer.getSpan(1))
      lineBuffer.toString().should.equal('(one\n)(three\n)')

    it 'removes line when its text is fully deleted and paritally selected line follows', ->
      lineBuffer.insertString(0, 'one\ntwo\nthree')
      spanNotToDelete = lineBuffer.getSpan(1)
      spanToDelete = lineBuffer.getSpan(2)
      lineBuffer.deleteRange(4, 6)
      should.equal(spanToDelete.indexParent, null)
      spanNotToDelete.should.equal(lineBuffer.getSpan(1))
      lineBuffer.toString().should.equal('(one\n)(ree\n)')

    it 'should fail to delete trailing newline', ->
      lineBuffer.insertString(0, 'one')
      indexDidChangeExpects = [
        (e) ->
          e.location.should.equal(3)
          e.replacedLength.should.equal(1)
          e.insertedString.should.equal('\n')
      ]
      lineBuffer.deleteRange(3, 1, '')
      lineBuffer.toString().should.equal('(one\n)')

    it 'should delete all', ->
      lineBuffer.insertString(0, 'one')
      indexDidChangeExpects = [
        (e) ->
          e.location.should.equal(0)
          e.replacedLength.should.equal(4)
          e.insertedString.should.equal('\n')
      ]
      lineBuffer.deleteRange(0, 4, '')
      lineBuffer.toString().should.equal('(\n)')

  describe 'Replace Text', ->

    it 'replaces text', ->
      lineBuffer.insertString(0, 'Hello world!')
      lineBuffer.replaceRange(3, 5, '')
      lineBuffer.toString().should.equal('(Helrld!\n)')

    it 'replaces text overlapping lines (not fully selected) case 1', ->
      lineBuffer.insertString(0, 'one\ntwo\nthree')
      spanNotToDelete = lineBuffer.getSpan(0)
      spanToDelete = lineBuffer.getSpan(1)
      lineBuffer.replaceRange(2, 3, 'hello')
      spanNotToDelete.should.equal(lineBuffer.getSpan(0))
      should.equal(spanToDelete.indexParent, null)
      lineBuffer.toString().should.equal('(onhellowo\n)(three\n)')

    it 'replaces text overlapping lines (not fully selected) case 2', ->
      lineBuffer.insertString(0, 'one\ntwo\nthree')
      spanNotToDelete = lineBuffer.getSpan(1)
      spanToDelete = lineBuffer.getSpan(2)
      lineBuffer.replaceRange(4, 6, 'hello')
      spanNotToDelete.should.equal(lineBuffer.getSpan(1))
      should.equal(spanToDelete.indexParent, null)
      lineBuffer.toString().should.equal('(one\n)(helloree\n)')

    it 'replaces text fully overlapping lines', ->
      lineBuffer.insertString(0, 'one\ntwo\nthree')
      spanToDelete = lineBuffer.getSpan(1)
      spanNotToChange = lineBuffer.getSpan(2)
      lineBuffer.replaceRange(4, 4, 'hello\n')
      should.equal(spanToDelete.indexParent, null)
      spanNotToChange.should.equal(lineBuffer.getSpan(2))
      lineBuffer.toString().should.equal('(one\n)(hello\n)(three\n)')

  describe 'Spans', ->

    it 'adds newline to last span when spans inserted after it', ->
      lineBuffer.insertSpans(0, [lineBuffer.createSpan('one'), lineBuffer.createSpan('two')])
      lineBuffer.insertSpans(0, [lineBuffer.createSpan('zero')])
      lineBuffer.insertSpans(3, [lineBuffer.createSpan('three')])
      lineBuffer.toString().should.equal('(zero\n)(one\n)(two\n)(three\n)')

    it 'removes newline from span when it becomes the last span', ->
      lineBuffer.insertString(0, 'one\ntwo\nthree')
      lineBuffer.removeSpans(0, 1)
      lineBuffer.toString().should.equal('(two\n)(three\n)')
      lineBuffer.removeSpans(1, 1)
      lineBuffer.toString().should.equal('(two\n)')

  describe 'Events', ->

    it 'posts change events when updating text in line', ->
      lineBuffer.insertSpans 0, [
        lineBuffer.createSpan('a'),
        lineBuffer.createSpan('b'),
        lineBuffer.createSpan('c')
      ]
      indexDidChangeExpects = [
        (e) ->
          e.location.should.equal(0)
          e.replacedLength.should.equal(1)
          e.insertedString.should.equal('moose')
      ]
      lineBuffer.replaceRange(0, 1, 'moose')

    it 'posts change events when inserting lines', ->
      indexDidChangeExpects = [
        (e) ->
          e.location.should.equal(0)
          e.replacedLength.should.equal(0)
          e.insertedString.should.equal('a\nb\nc\n')
        (e) ->
          e.location.should.equal(6)
          e.replacedLength.should.equal(0)
          e.insertedString.should.equal('d\n')
      ]
      lineBuffer.insertSpans 0, [
        lineBuffer.createSpan('a'),
        lineBuffer.createSpan('b'),
        lineBuffer.createSpan('c')
      ]
      lineBuffer.insertSpans 3, [
        lineBuffer.createSpan('d')
      ]

    it 'posts change events when removing lines', ->
      lineBuffer.insertSpans 0, [
        lineBuffer.createSpan('a'),
        lineBuffer.createSpan('b'),
        lineBuffer.createSpan('c')
      ]
      indexDidChangeExpects = [
        (e) ->
          e.location.should.equal(4)
          e.replacedLength.should.equal(2)
          e.insertedString.should.equal('')
      ]
      lineBuffer.removeSpans(2, 1)

    it 'posts change events when removing all lines', ->
      lineBuffer.insertSpans 0, [
        lineBuffer.createSpan('a'),
        lineBuffer.createSpan('b'),
        lineBuffer.createSpan('c')
      ]
      indexDidChangeExpects = [
        (e) ->
          e.location.should.equal(0)
          e.replacedLength.should.equal(6)
          e.insertedString.should.equal('')
      ]
      lineBuffer.removeSpans(0, 3)
