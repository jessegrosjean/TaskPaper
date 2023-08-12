module.exports =
class Config

  constructor: ->
    @map = new Map()

  get: (key) ->
    @map.get(key)

  set: (key, value) ->
    @map.set(key, value)
