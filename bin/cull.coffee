seq = require '../src/seq'
init_errors = require './errors'

down = require './down'
rm = require './rm'

module.exports = (tugboat, groupname, servicenames, callback) ->
  down tugboat, groupname, servicenames, ->
    rm tugboat, groupname, servicenames, ->
      callback() if callback?