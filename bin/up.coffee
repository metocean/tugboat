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
      
      groupname = groupname.replace '.yml', ''
      
      tasks = []
      
      console.log()
      console.log "  Updating #{groupname.blue}..."
      console.log()
      
      for _, service of results[groupname].services
        outputname = service.name.cyan
        outputname += ' ' while outputname.length < 36
        do (outputname, service) ->
          tasks.push (cb) ->
            if service.diff.iserror
              console.error "  #{outputname} #{'Error:'.red}"
              for m in service.diff.messages
                console.log "  #{outputname} #{m.red}"
              return cb()
            for m in service.diff.messages
              console.log "  #{outputname} #{m.magenta}"
            
            cb()
          
          for c in service.diff.stop
            do (c) ->
              tasks.push (cb) ->
                process.stdout.write "  #{outputname} Stopping #{c.container.Names[0].substr('1').cyan} "
                tugboat.ducke
                  .container c.container.Id
                  .stop (err, result) ->
                    if err?
                      console.error 'X'.red
                      if err.stack then console.error err.stack
                      else console.error err
                      return
                    console.error '√'.green
                    cb()
          for c in service.diff.rm
            do (c) ->
              tasks.push (cb) ->
                process.stdout.write "  #{outputname} Deleting #{c.container.Names[0].substr('1').cyan} "
                tugboat.ducke
                  .container c.container.Id
                  .rm (err, result) ->
                    if err?
                      console.error 'X'.red
                      if err.stack then console.error err.stack
                      else console.error err
                      return
                    console.error '√'.green
                    cb()
          for c in service.diff.start
            do (c) ->
              tasks.push (cb) ->
                process.stdout.write "  #{outputname} Starting #{c.container.Names[0].substr('1').cyan} "
                tugboat.ducke
                  .container c.container.Id
                  .start (err, result) ->
                    if err?
                      console.error 'X'.red
                      if err.stack then console.error err.stack
                      else console.error err
                      return
                    console.error '√'.green
                    cb()
          for c in service.diff.keep
            do (c) ->
              tasks.push (cb) ->
                console.log "  #{outputname} Keeping #{c.container.Names[0].substr('1').cyan}"
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
                process.stdout.write "  #{outputname} Creating #{newname.cyan} (#{service.service.params.Image}) "
                
                tugboat.up service.service, newname, (err) ->
                  if err?
                    console.error 'X'.red
                    if err.stack then console.error err.stack
                    else console.error err
                  else
                    console.error '√'.green
                  cb()
      
      series tasks, ->
        console.log()