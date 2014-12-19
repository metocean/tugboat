series = require '../src/series'
init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames, isdryrun) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    console.log()
    if Object.keys(tugboat._groups).length is 0
      console.error '  There are no groups defined in this directory'.red
      console.error()
      process.exit 1
    
    tugboat.ps (err, groups) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      if !groups[groupname]?
        console.error "  The group '#{groupname}' is not available in this directory".red
        console.error()
        process.exit 1
      
      group = groups[groupname]
      
      if servicenames.length is 0
        servicenames = Object.keys group.services
      
      haderror = no
      for name in servicenames
        if !group.services[name]?
          console.error "  The service '#{name}' is not available in the group '#{groupname}'".red
          haderror = yes
      if haderror
        process.exit 1
      
      tugboat.ducke.ls (err, imagerepo) ->
        if err?
          console.error()
          console.error '  docker is down'.red
          console.error()
          process.exit 1
        
        tugboat.ps (err, groups) ->
          if err?
            console.error()
            console.error '  docker is down'.red
            console.error()
            process.exit 1
          
          g = groups[groupname]
          
          tasks = []
          if isdryrun
            console.log "  Dry run for #{groupname.blue}..."
          else
            console.log "  Starting #{groupname.blue}..."
          console.log()
          for servicename in servicenames
            do (servicename) ->
              tasks.push (cb) ->
                s = g.services[servicename]
                
                servicetasks = []
                
                if !s.isknown
                  outputname = servicename
                  outputname += ' (unknown)'.magenta
                  outputname += ' ' while outputname.length < 36
                  
                  for c in s.containers
                    do (c) ->
                      name = c.container.Names[0].substr 1
                      if c.inspect.State.Running
                        servicetasks.push (cb) ->
                          console.log "  #{outputname.blue} stopping container #{name.cyan}"
                          return cb() if isdryrun
                          tugboat.ducke
                            .container c.container.Id
                            .stop (err, result) ->
                              if err?
                                console.error err
                                console.error()
                              cb()
                      servicetasks.push (cb) ->
                        console.log "  #{outputname.blue} deleting #{'unknown'.magenta} container #{name.cyan}"
                        return cb() if isdryrun
                        tugboat.ducke
                          .container c.container.Id
                          .rm (err, result) ->
                            if err?
                              console.error err
                              console.error()
                            cb()
                else
                  outputname = servicename
                  outputname += ' ' while outputname.length < 26
                
                  tagname = s.service.params.Image
                  if tagname.indexOf ':' is -1
                    tagname += ':latest'
                  
                  if !imagerepo.tags[tagname]?
                    console.error "  #{outputname.blue} image #{s.service.params.Image.red} is not available"
                    return cb()
                  image = imagerepo.tags[tagname]
                  
                  primary = null
                  excess = []
                  
                  for c in s.containers
                    if image.image.Id is c.inspect.Image
                      primary = c
                    else
                      excess.push c
                  
                  for e in excess
                    do (e) ->
                      name = e.container.Names[0].substr 1
                      servicetasks.push (cb) ->
                        console.log "  #{outputname.blue} image #{image.image.Id.substr(0, 12).cyan} is newer than #{c.inspect.Image.substr(0, 12).cyan}"
                        cb()
                      if e.inspect.State.Running
                        servicetasks.push (cb) ->
                          console.log "  #{outputname.blue} stopping old container #{name.cyan}"
                          return cb() if isdryrun
                          tugboat.ducke
                            .container e.container.Id
                            .stop (err, result) ->
                              if err?
                                console.error err
                                console.error()
                              cb()
                      servicetasks.push (cb) ->
                        console.log "  #{outputname.blue} removing old container #{name.cyan}"
                        return cb() if isdryrun
                        tugboat.ducke
                          .container e.container.Id
                          .rm (err, result) ->
                            if err?
                              console.error err
                              console.error()
                            cb()
                  
                  if primary?
                    name = primary.container.Names[0].substr 1
                    if primary.inspect.State.Running
                      servicetasks.push (cb) ->
                        console.log "  #{outputname.blue} container #{name.cyan} already #{'running'.green}"
                        cb()
                    else
                      servicetasks.push (cb) ->
                        console.log "  #{outputname.blue} starting existing container #{name.cyan}"
                        return cb() if isdryrun
                        tugboat.ducke
                          .container primary.container.Id
                          .start (err, result) ->
                            if err?
                              console.error err
                            cb()
                  else
                    servicetasks.push (cb) ->
                      newname = "#{groupname}_#{servicename}"
                      newindex = 1
                      newindex++ while s.containers
                        .filter (c) -> c.index is newindex
                        .length isnt 0
                      newname += "_#{newindex}"
                      console.log "  #{outputname.blue} starting new container #{newname.cyan} (#{s.service.params.Image})"
                      return cb() if isdryrun
                      
                      tugboat.up s.service, newname, (err) ->
                        if err?
                          console.error err
                        cb()
                
                series servicetasks, cb
          
          series tasks, ->
            console.log()