seq = require '../src/seq'
cull = require './cull'
up = require './up'

module.exports = (tugboat, groupname, servicenames, callback) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, groups) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      groupstoprocess = null
      if groupname?
        groupname = groupname.replace '.yml', ''
        
        if !groups[groupname]?
          console.error()
          console.error "  Cannot up #{groupname.red}, #{groupname}.yml not found in this directory"
          console.error()
          process.exit 1
        
        group = groups[groupname]
        
        if !group.isknown
          console.error()
          console.error "  Cannot recreate #{groupname.red}, #{groupname}.yml not found in this directory"
          console.error()
          process.exit 1
        
        groupstoprocess = [group]
      
      else
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
        if !g.isknown
          console.error()
          console.error "  Cannot up #{g.name.red}, #{groupname}.yml file not found in this directory"
          continue
        do (g) ->
          seq (cb) ->
            cull tugboat, g, [], ->
              up tugboat, g, []
            cb()
      
      seq (cb) ->
        cb()
        callback() if callback?