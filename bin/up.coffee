series = require '../src/series'
init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, results) ->
      return console.err if err?
      
      tasks = []
      
      console.log()
      console.log "  Updating #{groupname.blue}..."
      console.log()
      
      for _, service of results[groupname].services
        do (service) ->
          tasks.push (cb) ->
            console.log "  #{service.name.cyan}:"
          
            if service.diff.iserror
              console.error "  Error:".red
              for m in service.diff.messages
                console.log "  #{m}"
              return cb()
            for m in service.diff.messages
              console.log "    #{m}"
            
            cb()
          
          for c in service.diff.stop
            do (c) ->
              tasks.push (cb) ->
                console.log "    Stopping #{c.container.Names[0].substr('1').green}"
                tugboat.ducke
                  .container c.container.Id
                  .stop (err, result) ->
                    if err?
                      console.error err
                    cb()
          for c in service.diff.rm
            do (c) ->
              tasks.push (cb) ->
                console.log "    Deleting #{c.container.Names[0].substr('1').green}"
                tugboat.ducke
                  .container c.container.Id
                  .rm (err, result) ->
                    if err?
                      console.error err
                    cb()
          for c in service.diff.start
            do (c) ->
              tasks.push (cb) ->
                console.log "    Starting #{c.container.Names[0].substr('1').green}"
                tugboat.ducke
                  .container c.container.Id
                  .start (err, result) ->
                    if err?
                      console.error err
                    cb()
          for c in service.diff.keep
            do (c) ->
              tasks.push (cb) ->
                console.log "    Keeping #{c.container.Names[0].substr('1').green}"
                cb()
          
          if service.diff.create > 0
            for i in [1..service.diff.create]
              tasks.push (cb) ->
                newname = "#{groupname}_#{service.name}"
                newindex = 1
                newindex++ while service.containers
                  .filter (c) -> c.index is newindex.toString()
                  .length isnt 0
                newname += "_#{newindex}"
                console.log "    Creating new container #{newname.cyan} (#{service.service.params.Image})"
                
                tugboat.up service.service, newname, (err) ->
                  if err?
                    console.error err
                  cb()
          
          tasks.push (cb) ->
            console.log()
            cb()
      
      series tasks, ->