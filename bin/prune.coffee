series = require '../src/series'
init_errors = require './errors'

module.exports = (tugboat, groupnames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    tugboat.ps (err, groups) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      if Object.keys(groups).length is 0
        console.log()
        console.log '  There are no groups defined in this directory'.magenta
        console.log '  or running containers that match'.magenta
        console.log()
        return
      
      tasks = []
      for groupname in groupnames
        do (groupname) ->
          if !groups[groupname]?
            tasks.push (cb) ->
              console.log()
              console.log "  #{groupname.red} not found"
          else
            tasks.push (cb) ->
              console.log()
              console.log "  #{groupname.blue}:"
              cb()
            g = groups[groupname]
            for servicename, s of g.services
              for c in s.containers
                do (servicename, s, c) ->
                  name = c.container.Names[0].substr 1
                  name += ' ' while name.length < 32
                  if s.isknown
                    tasks.push (cb) ->
                      console.log "    #{name.cyan} #{'known'.green}"
                      cb()
                  else
                    if c.inspect.State.Running
                      tasks.push (cb) ->
                        console.log "    #{name.cyan} #{'stopping'.red}"
                        tugboat.ducke
                          .container c.container.Id
                          .stop (err) ->
                            if err?
                              console.error err
                            cb()
                    tasks.push (cb) ->
                      console.log "    #{name.cyan} #{'deleting'.red}"
                      tugboat.ducke
                        .container c.container.Id
                        .rm (err) ->
                          if err?
                            console.error err
                          cb()
      
      series tasks, ->
        console.log()