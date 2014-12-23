require 'colors'
init_errors = require './errors'

build = require './build'

module.exports =
  status: require './status'
  diff: require './diff'
  up: require './up'
  rm: require './rm'
  down: require './down'
  ps: require './ps'
  pull: require './pull'
  
  # Different cache options for the same build function
  build: (tugboat, names) ->
    build tugboat, names, yes
  rebuild: (tugboat, names) ->
    build tugboat, names, no