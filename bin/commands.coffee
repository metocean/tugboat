require 'colors'
series = require '../src/series'
init_errors = require './errors'

build = require './build'
up = require './up'

module.exports =
  status: require './status'
  
  # Dry run vs actually doing it
  diff: (tugboat, groupname, servicenames) ->
    up tugboat, groupname, servicenames, yes
  up: (tugboat, groupname, servicenames) ->
    up tugboat, groupname, servicenames, no
  
  rm: require './rm'
  down: require './down'
  ps: require './ps'
  
  # Different cache options for the same build function
  build: (tugboat, names) ->
    build tugboat, names, yes
  rebuild: (tugboat, names) ->
    build tugboat, names, no