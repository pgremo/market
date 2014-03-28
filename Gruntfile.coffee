config = require('./config').config

module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffeelint:
      options:
        max_line_length:
          value: 120
          level: "warn"
        no_trailing_whitespace:
          level: "warn"
      app: ['public/coffeescripts/**/*.coffee']
    exec:
      dev:
        options:
          stdout: true
          stderr: true
        command: 'node-dev app.coffee'

  require('load-grunt-tasks')(grunt)
  grunt.loadNpmTasks 'grunt-exec'
  grunt.registerTask 'default', ['exec:dev']
