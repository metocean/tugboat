seq = require '../src/seq'
init_errors = require './errors'

cull = require './cull'
up = require './up'

module.exports = (tugboat, groupname, servicenames, callback) ->
  cull tugboat, groupname, servicenames, ->
    up tugboat, groupname, servicenames, ->
      callback() if callback?