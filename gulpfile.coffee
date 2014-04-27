gulp = require 'gulp'
coffeelint = require 'gulp-coffeelint'
livereload = require 'gulp-livereload'
nodemon = require 'gulp-nodemon'
mocha = require 'gulp-mocha'
_ = require 'lodash'

paths =
  server: [
    'app.coffee',
    'routes/*.coffee',
    'lib/*.coffee',
    'data/*.coffee'
  ],
  test: 'test/**/*.coffee'
  coffee: 'public/js/*.coffee'
  css: 'public/css/*.css'
  jade: 'views/*.jade'

gulp.task 'lint', ->
  gulp
  .src _.flatten [paths.coffee, paths.server, paths.test, 'gulpfile.coffee']
  .pipe coffeelint()
  .pipe coffeelint.reporter()

gulp.task 'test', ->
  gulp
  .src paths.test
  .pipe mocha reporter: 'spec'

gulp.task 'server', ->
  nodemon script: './app.coffee'
  .on 'start', () ->
    console.log """
        Starting up context, serving on [localhost:3000]
        Hit CTRL-C to stop the server
      """
  .on 'quit', () ->
    console.log 'App has quit'
  .on 'restart', (files) ->
    console.log "App restarted due to: #{files}"

gulp.task 'watch', ['server'], ->
  gulp.watch paths.coffee, ['lint']
  server = livereload()
  globs = _.flatten [paths.coffee, paths.css, paths.jade]
  gulp.watch globs, (file) ->
    setTimeout -> server.changed file.path
    , 500

gulp.task 'default', ['watch']

gulp.task 'build', ['lint', 'test']
