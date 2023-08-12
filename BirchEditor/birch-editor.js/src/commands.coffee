{ CompositeDisposable, Disposable } = require 'event-kit'
{ util }  = require 'birch-outline'
_ = require 'underscore-plus'
assert = util.assert

module.exports =
class Commands

  constructor: ->
    @commands = new Map()

  add: (target, commandName, callback, override) ->
    if typeof commandName is 'object'
      commands = commandName
      disposable = new CompositeDisposable
      for commandName, callback of commands
        disposable.add @add(target, commandName, callback)
      return disposable

    if override
      assert(@commands.get(commandName)?)
    else
      assert(not @commands.get(commandName))

    @commands.set(commandName, callback)
    new Disposable =>
      @commands.delete(commandName)

  override: (target, commandName, callback) ->
    if typeof commandName is 'object'
      commands = commandName
      disposable = new CompositeDisposable
      for commandName, callback of commands
        disposable.add @add(target, commandName, callback, true)
      return disposable
    @add(target, commandName, callback, true)

  hasCommand: (target, commandName) ->
    @commands.get(commandName)?

  findCommands: (target) ->
    results = []
    @commands.forEach (callback, commandName) ->
      results.push
        command: commandName
        displayName: _.humanizeEventName(commandName)
    results.sort (a, b) ->
      a.displayName.localeCompare(b.displayName)
    results

  dispatch: (target, commandName, detail, completedCallback) ->
    if callback = @commands.get(commandName)
      if callback.length > 1
        callback.call(target, detail, completedCallback)
      else
        callback.call(target, detail)
        completedCallback?(true)
    else
      completedCallback?(false)
