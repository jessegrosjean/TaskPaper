{Emitter, CompositeDisposable} = require 'event-kit'

module.exports =
class Preferences

  @nativePreferences = null

  constructor: ->
    @emitter = new Emitter
    @map = new Map()

  onDidChange: (callback) ->
    @emitter.on "did-change", callback

  onDidChangeKey: (key, callback) ->
    @emitter.on "did-change-#{key}", callback

  get: (key) ->
    if @nativePreferences
      @nativePreferences.getPreference(key)
    else
      @map.get(key)

  set: (key, value) ->
    if @nativePreferences
      @nativePreferences.storePreference(key, value)
    else
      @map.set(key, value)
    @emitter.emit "did-change-#{key}"
    @emitter.emit "did-change"
