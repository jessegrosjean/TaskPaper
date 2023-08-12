BirchOutline = require 'birch-outline'
Preferences = require './preferences'
Commands = require './commands'

BirchOutline.preferences = new Preferences
BirchOutline.commands = new Commands

module.exports = BirchOutline
