webpack = require 'webpack-stream'

uglifyConfig =
  compress:
    warnings: false
  mangle:false

module.exports =
  devtool: 'source-map'
  entry:
    'bircheditor': './lib/index.js'
  output:
    path: './min'
    library: '[name]'
    filename: '[name].js'
  module:
    loaders: [
      test: /\.json$/,
      loader: "json-loader"
    ]
  plugins: [
    #new webpack.webpack.optimize.UglifyJsPlugin(uglifyConfig)
  ]
