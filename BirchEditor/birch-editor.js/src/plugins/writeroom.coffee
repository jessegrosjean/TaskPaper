Birch = require '../birch'

module.exports = () ->

  Birch.commands.add 'outline-editor',
    'outline-editor:toggle-bold': (e) -> @toggleTextAttribute 'b'
    'outline-editor:toggle-italic': (e) -> @toggleTextAttribute 'i'
