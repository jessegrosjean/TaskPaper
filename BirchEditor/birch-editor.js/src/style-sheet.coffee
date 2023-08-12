# Copyright (c) 2015 Jesse Grosjean. All rights reserved.

CssSelectorParser = require('css-selector-parser').CssSelectorParser
parseColorLib = require 'parse-color'
specificity = require 'specificity'
{ Item }  = require 'birch-outline'
cssParse = require 'css/lib/parse'
less = require './less'

selectorParser = new CssSelectorParser()
selectorParser.registerNestingOperators('>')
selectorParser.registerAttrEqualityMods('^', '$', '*')
selectorParser.enableSubstitutes()

parseStringList = (string) ->
  results = []
  for each in string.split(',')
    results.push(parseString(each))
  results

parseString = (string) ->
  end = string.length - 1
  if (string[0] is "'" and string[end] is "'") or (string[0] is '"' and string[end] is '"')
    string = string.substring(1, end)
    string = string.replace(/\\/g, '')
  string

parseColor = (string) ->
  parsedColor = parseColorLib(string)
  parsedColor.rgba ? parsedColor.rgb

parseBool = (string) ->
  string is 'true' or string is ''

propertyParserLookup =
  'tint-color': parseColor
  'backdrop-color': parseColor

  'color': parseColor
  'font-family': parseStringList
  'font-style': null
  'font-weight': null
  'font-size': parseFloat
  'line-height-multiple': parseFloat
  'paragraph-spacing-before': parseFloat
  'paragraph-spacing-after': parseFloat

  # Search bar
  'secondary-text-color': parseColor
  'error-text-color': parseColor
  'placeholder-color': parseColor

  # Editor
  'ui-scale': parseFloat
  'background-color': parseColor
  'invisibles-color': parseColor
  'drop-indicator-color': parseColor
  'selection-background-color': parseColor
  'guide-line-color': parseColor
  'guide-line-width': parseFloat
  'fold-color': parseColor
  'caret-color': parseColor
  'caret-width': parseFloat
  'item-indent': parseFloat
  'editor-wrap-to-column': parseFloat
  'item-wrap-to-column': parseFloat
  'top-padding-percent': parseFloat
  'bottom-padding-percent': parseFloat
  'typewriter-scroll-percent': parseFloat

  # Item
  'handle-size': parseFloat
  'handle-color': parseColor
  'handle-border-color': parseColor
  'handle-border-width': parseFloat

  # Run
  'cursor': null
  'text-decoration': null
  'text-underline': null
  'text-underline-color': parseColor
  'text-strikethrough': null
  'text-strikethrough-color': parseColor
  'text-baseline-offset': parseFloat
  'text-expansion': parseFloat

parsePropertyValue = (property, value) ->
  if value
    parser = propertyParserLookup[property]
    if parser
      parser(value)
    else
      value
  else
    undefined

module.exports =
class StyleSheet

  constructor: (lessRules='') ->
    @idsToRules = new Map()
    @sortedSelectors = []
    @computedStylesToKeys = new Map()

    nextID = 0
    rulesList = []

    less.render lessRules, {}, (error, cssResult) =>
      if error
        console.log("Error parsing lessRules: #{error}")
        errorCallback?(error)
      else
        try
          parsedrules = cssParse(cssResult.css).stylesheet.rules
        catch error
          console.log("Error parsing cssRules: #{cssResult.css}")
          parsedrules = []

        for eachParsedRule in parsedrules
          if eachParsedRule.type is 'rule'
            eachRule =
              id: "id-#{nextID++}"
              selectors: []
              declarations: {}

            for eachSelector in eachParsedRule.selectors
              try
                selector = specificity.calculate(eachSelector)[0]
                selector.selectorAST = selectorParser.parse(eachSelector)
                eachRule.selectors.push(selector)
                selector.rule = eachRule
              catch error
                console.log("Error parsing selector: #{eachSelector}")

            for eachDeclaration in eachParsedRule.declarations
              try
                eachRule.declarations[eachDeclaration.property] = parsePropertyValue(eachDeclaration.property, eachDeclaration.value)
              catch error
                console.log("Error parsing property: #{eachDeclaration.property} value: #{eachDeclaration.value}")

            @idsToRules.set(eachRule.id, eachRule)
            rulesList.push(eachRule)

    declarationOrder = 0
    for eachRule in rulesList
      for eachSelector in eachRule.selectors
        eachSelector.declarationOrder = declarationOrder++
        @sortedSelectors.push(eachSelector)
    @sortedSelectors.sort (a, b) ->
      sort = a.specificity.localeCompare(b.specificity)
      if a.specificity is b.specificity
        return a.declarationOrder - b.declarationOrder
      else if a.specificity < b.specificity
        return -1
      else
        return 1

  ###
  Section: Styles
  ###

  getStyleForElement: (element) ->
    @getStyleForKey(@getStyleKeyForElement(element))

  getStyleKeyForElement: (element) ->
    matches = []
    try
      for eachSelector in @sortedSelectors
        if StyleSheet.matchesSelector(eachSelector.selectorAST, element)
          matches.push(eachSelector.rule.id)
    catch error
      console.log("Exception matching StyleSheet selector: #{error}")

    if matches.length
      matches.join(',')
    else
      null

  getStyleForKey: (key) ->
    unless style = @computedStylesToKeys.get(key)
      style = {}
      if key
        for eachRuleID in key.split(',')
          if declarations = @idsToRules.get(eachRuleID)?.declarations
            Object.assign(style, declarations)
      @computedStylesToKeys.set(key, style)
    style

  ###
  Section: Computed Styles
  ###

  getComputedStyleForElement: (element, cache) ->
    @getComputedStyleForKeyPath(@getComputedStyleKeyPathForElement(element, cache), cache)

  getComputedStyleKeyPathForElement: (element, cache) ->
    unless element
      return null

    if typeof element is 'string'
      element =
        tagName: element
        attributes: {}

    if element.computedStyleKeyPath
      return element.computedStyleKeyPath
    key = @getStyleKeyForElement(element) ? '*'
    if element.parentNode
      element.computedStyleKeyPath = "#{@getComputedStyleKeyPathForElement(element.parentNode, cache)}>#{key}"
    else
      element.computedStyleKeyPath = key
    element.computedStyleKeyPath

  getComputedStyleForKeyPath: (keyPath, cache) ->
    computedStyle = cache?[keyPath]
    unless computedStyle
      keyPathItems = keyPath.split('>')
      computedStyle = Object.assign({}, @getStyleForKey(keyPathItems.pop()))
      if keyPathItems.length
        ancestorsComputedStyle = @getComputedStyleForKeyPath(keyPathItems.join('>'))
        if ancestorsComputedStyle
          computedStyle['color'] ?= ancestorsComputedStyle['color']
          computedStyle['font-family'] ?= ancestorsComputedStyle['font-family']
          computedStyle['font-style'] ?= ancestorsComputedStyle['font-style']
          computedStyle['font-weight'] ?= ancestorsComputedStyle['font-weight']
          computedStyle['font-size'] ?= ancestorsComputedStyle['font-size']
          computedStyle['line-height-multiple'] ?= ancestorsComputedStyle['line-height-multiple']
        cache?[keyPath] = computedStyle
    computedStyle

  ###
  Section: Private
  ###

  @matchesSelector: (selector, element) ->
    if typeof selector is 'string'
      try
        selector = selectorParser.parse(selector)
      catch error
        console.log("Error parsing selector: #{error}")
        return false

    if typeof element is 'string'
      element =
        tagName: element
        attributes: {}

    rule1 = selector.rule
    rule2 = rule1.rule

    if rule2
      rules = [rule1, rule2]

      each = rule2.rule
      while each
        rules.push(each)
        each = each.rule

      for rule in rules by -1
        nesting = rule.nestingOperator
        unless (nesting is undefined or nesting is '>')
          throw Error('Invalid nesting operator: #{nestingOperator}. Only ">" nesting is allowed.')
        unless element
          return false
        unless @matchesRule(rule, element)
          return false
        element = element.parentNode

      true
    else
      @matchesRule(rule1, element)

  @matchesRule: (rule, element) ->
    if rule.tagName and rule.tagName isnt '*' and rule.tagName isnt element.tagName
      return false

    if rule.attrs
      for attr in rule.attrs
        value = element.attributes?[attr.name] ? element[attr.name]

        unless value?
          return false

        switch attr.operator
          when undefined
            break
          when '='
            value = Item.objectToAttributeValueString(value)
            unless value is attr.value
              return false
          when '^='
            value = Item.objectToAttributeValueString(value)
            unless value.slice(0, attr.value.length) is attr.value
              return false
          when '*='
            value = Item.objectToAttributeValueString(value)
            if value.indexOf(attr.value) is -1
              return false
          when '$='
            value = Item.objectToAttributeValueString(value)
            unless value.slice(-attr.value.length) is attr.value
              return false
          else
            throw Error('Undefined attribute operator: #{attr.operator}')
    true
