gulp = require 'gulp'
gutil = require 'gulp-util'
shell = require 'gulp-shell'
clean = require 'gulp-clean'
mocha = require 'gulp-mocha'
cache = require 'gulp-cached'
coffee = require 'gulp-coffee'
webpack = require 'webpack-stream'
coffeelint = require 'gulp-coffeelint'
Renderer = require('birch-doc').Renderer
webpackConfig = require './webpack.config'

gulp.task 'clean', ->
  cache.caches = {}
  gulp.src(['.coffee/', 'lib/', 'doc/api/', 'min/']).pipe(clean())

gulp.task 'peg:date-time', shell.task('node_modules/pegjs/bin/pegjs --cache  --allowed-start-rules DateTimeExpression,Time,Duration src/date-time-parser.pegjs')
gulp.task 'peg:item-path', shell.task('node_modules/pegjs/bin/pegjs --cache  --allowed-start-rules ItemPathExpression,StringValue src/item-path-parser.pegjs')
gulp.task 'peg', ['peg:date-time', 'peg:item-path']

gulp.task 'test', ['peg'], ->
  gulp.src(['test/**/*-spec.coffee'], read: false)
    .pipe(mocha(reporter: 'nyan'))

gulp.task 'javascript', ['peg'], ->
  gulp.src('src/**/*.js')
    .pipe(cache('javascript'))
    .pipe(gulp.dest('lib/'))

gulp.task 'coffeescript', ->
  gulp.src('./src/**/*.coffee')
    .pipe(cache('coffeescript'))
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
    .pipe(coffee(bare: true).on('error', gutil.log))
    .pipe(gulp.dest('lib/'))

gulp.task 'doc', ->
  Renderer.renderModules(['.'], 'doc/api/', layout: 'class')

gulp.task 'webpack', ['javascript', 'coffeescript'], ->
  config = Object.create(webpackConfig)
  config.output.path = null
  gulp.src('lib/index.js')
    .pipe(webpack(config))
    .pipe(gulp.dest('min/'))

gulp.task 'webpack:watch', ['javascript', 'coffeescript'], ->
  config = Object.create(webpackConfig)
  config.watch = true
  config.output.path = null
  config.plugins = [] # remove uglify
  gulp.src('lib/index.js')
    .pipe(webpack(config))
    .pipe(gulp.dest('min/'))

gulp.task 'prepublish', ['clean', 'test', 'doc'], ->
  gulp.start('webpack')

gulp.task 'watch', ['clean', 'test', 'doc'], ->
  gulp.watch('src/**/*', ['javascript', 'coffeescript', 'test', 'doc'])
  gulp.watch('test/**/*', ['test'])
  gulp.start('webpack:watch')

gulp.task 'default', ['watch'], ->
