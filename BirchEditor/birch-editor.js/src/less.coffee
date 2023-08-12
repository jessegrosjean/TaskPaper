
# Lots of extra ()'s in file because otherwise donna.generateMetadata fails on this file

# Doesnt work to require less directly... get browser stuff and won't run in
# JavaScriptCore. But requring these things manually seems to work well. I've
# commented out all the requires that I can while still keeping it working.
fileManagers = []
SourceMapBuilder = null

module.exports =
  version: [2, 7, 1]
  #data: require('less/lib/less/data'),
  #tree: require('less/lib/less/tree'),
  Environment: (Environment = require('less/lib/less/environment/environment'))
  #AbstractFileManager: require("less/lib/less/environment/abstract-file-manager"),
  environment: (environment = new Environment(environment, fileManagers))
  #visitors: require('less/lib/less/visitors'),
  #Parser: require('less/lib/less/parser/parser'),
  functions: (require('less/lib/less/functions')(environment))
  #contexts: require("less/lib/less/contexts"),
  #SourceMapOutput: (SourceMapOutput = require('less/lib/less/source-map-output')(environment)),
  #SourceMapBuilder: (SourceMapBuilder = require('less/lib/less/source-map-builder')(SourceMapOutput, environment)),
  ParseTree: (ParseTree = (require('less/lib/less/parse-tree')(SourceMapBuilder)))
  ImportManager: (ImportManager = (require('less/lib/less/import-manager')(environment)))
  render: (require("less/lib/less/render")(environment, ParseTree, ImportManager))
  parse: (require("less/lib/less/parse")(environment, ParseTree, ImportManager))
  #LessError: require('less/lib/less/less-error'),
  #transformTree: require('less/lib/less/transform-tree'),
  #utils: require('less/lib/less/utils'),
  #PluginManager: require('less/lib/less/plugin-manager'),
  #logger: require('less/lib/less/logger')
