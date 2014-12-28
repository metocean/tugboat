series = require '../src/series'
init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, results) ->
      if err?
        if err.stack then console.error err.stack
        else console.error err
        return
      
      tasks = []
      
      console.log()
      console.log "  Updating #{groupname.blue}..."
      console.log()
      
      for _, service of results[groupname].services
        outputname = service.name.blue
        outputname += ' ' while outputname.length < 36
        do (outputname, service) ->
          tasks.push (cb) ->
            if service.diff.iserror
              console.error "  #{outputname} #{'Error:'.red}"
              for m in service.diff.messages
                console.log "  #{outputname} #{m}"
              return cb()
            for m in service.diff.messages
              console.log "  #{outputname} #{m}"
            
            cb()
          
          for c in service.diff.stop
            do (c) ->
              tasks.push (cb) ->
                console.log "  #{outputname} Stopping #{c.container.Names[0].substr('1').green}"
                tugboat.ducke
                  .container c.container.Id
                  .stop (err, result) ->
                    if err?
                      if err.stack then console.error err.stack
                      else console.error err
                      return
                    cb()
          for c in service.diff.rm
            do (c) ->
              tasks.push (cb) ->
                console.log "  #{outputname} Deleting #{c.container.Names[0].substr('1').green}"
                tugboat.ducke
                  .container c.container.Id
                  .rm (err, result) ->
                    if err?
                      if err.stack then console.error err.stack
                      else console.error err
                      return
                    cb()
          for c in service.diff.start
            do (c) ->
              tasks.push (cb) ->
                console.log "  #{outputname} Starting #{c.container.Names[0].substr('1').green}"
                tugboat.ducke
                  .container c.container.Id
                  .start (err, result) ->
                    if err?
                      if err.stack then console.error err.stack
                      else console.error err
                      return
                    cb()
          for c in service.diff.keep
            do (c) ->
              tasks.push (cb) ->
                console.log "  #{outputname} Keeping #{c.container.Names[0].substr('1').green}"
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
                console.log "  #{outputname} Creating new container #{newname.cyan} (#{service.service.params.Image})"
                
                tugboat.up service.service, newname, (err) ->
                  if err?
                    if err.stack then console.error err.stack
                    else console.error err
                    return
                  cb()
      
      series tasks, ->
        console.log()