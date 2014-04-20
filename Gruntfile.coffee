'use strict';

request = require 'request'

module.exports = (grunt) ->
  require('time-grunt') grunt
  require('load-grunt-tasks') grunt

  reloadPort = 35729

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    develop:
      server:
        file: 'app.coffee'
        cmd: 'coffee'
    watch:
      options:
        nospawn: true,
        livereload: reloadPort
      server:
        files: [
          'app.coffee',
          'routes/*.coffee'
        ],
        tasks: ['develop', 'delayed-livereload']
      js:
        files: ['public/js/*.coffee']
        options:
          livereload: reloadPort
      css:
        files: ['public/css/*.css']
        options:
          livereload: reloadPort
      jade:
        files: ['views/*.jade']
        options:
          livereload: reloadPort

  grunt.config.requires 'watch.server.files'
  files = grunt.config 'watch.server.files'
  files = grunt.file.expand files

  grunt.registerTask 'delayed-livereload', 'Live reload after the node server has restarted.', () ->
    done = this.async()
    setTimeout () ->
      request.get "http://localhost:#{reloadPort}/changed?files=#{files.join(',')}",  (err, res) ->
        reloaded = !err && res.statusCode is 200
        if reloaded
          grunt.log.ok 'Delayed live reload successful.'
        else
          grunt.log.error 'Unable to make a delayed live reload.'
        done reloaded
    , 500

  grunt.registerTask 'default', ['develop', 'watch']