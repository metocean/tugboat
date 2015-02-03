seq = require '../src/seq'
init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames, callback) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, groups) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      console.log()
      
      groupstoprocess = []
      if groupname
        groupname = groupname.replace '.yml', ''
        if !groups[groupname]?
          console.error "  The group '#{groupname}' is not available in this directory".red
          console.error()
          process.exit 1
        groupstoprocess.push groups[groupname]
      else
        groupstoprocess.push g for _, g of groups
      
      for g in groupstoprocess
        do (g) ->
          seq (cb) ->
            console.log "  Stopping #{g.name.blue}..."
            console.log()
            cb()
          
          servicestoprocess = []
          if servicenames.length isnt 0
            haderror = no
            for name in servicenames
              if !g.services[name]?
                console.error "  The service '#{name}' is not available in the group '#{g.name}'".red
                haderror = yes
              else
                servicestoprocess.push g.services[name]
            if haderror
              process.exit 1
          else
            servicestoprocess.push service for _, service of g.services
          
          servicestoprocess = servicestoprocess
            .filter (s) ->
              s.containers
                .filter (c) -> c.inspect.State.Running
                .length isnt 0
          
          if servicestoprocess.length is 0
            seq (cb) ->
              console.log "  No containers to stop".magenta
              cb()
            
          sname = (s) ->
            name = s.name
            name += ' ' while name.length < 32
            name = name.cyan
            if s.service?
              name = s.service.pname.cyan
            name
          
          for s in servicestoprocess
            outputname = sname s
            for c in s.containers
              do (outputname, s, c) ->
                seq "#{outputname} Stopping #{c.container.Names[0].substr(1).cyan}", (cb) ->
                  tugboat.stop g, s, c, (err) ->
                    return cb err if err?
                    cb()
          
          seq (cb) ->
            console.log()
            cb()
      
      seq (cb) ->
        cb()
        callback() if callback?