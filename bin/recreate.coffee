seq = require '../src/seq'
cull = require './cull'
up = require './up'

module.exports = (tugboat, groupname, servicenames, callback) ->
  if groupname?
    return cull tugboat, groupname, servicenames, ->
      up tugboat, groupname, servicenames, ->
        callback() if callback?
  
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, groups) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      groupstoprocess = Object.keys groups
        .filter (g) ->
          g = groups[g]
          Object.keys g.services
            .filter (s) ->
              s = g.services[s]
              return no if !s.service?
              s.containers
                .filter (c) -> c.inspect.State.Running
                .length isnt 0
            .length isnt 0
      
      for g in groupstoprocess
        do (g) ->
          seq (cb) ->
            cull tugboat, g, [], ->
              up tugboat, g, []
            cb()
      
      seq (cb) ->
        cb()
        callback() if callback?