seq = require '../src/seq'
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
      
      console.log()
      console.log "  Updating #{groupname.blue}..."
      console.log()
      
      group = results[groupname]
      
      for _, service of group.services
        outputname = service.name.cyan
        outputname += ' ' while outputname.length < 36
        do (outputname, service) ->
          seq "#{outputname} Diffing", (cb) ->
            if service.diff.iserror
              return cb service.diff.messages
            for m in service.diff.messages
              console.log "  #{m.magenta}"
            cb()
          
          for c in service.diff.stop
            do (c) ->
              seq "#{outputname} Stopping #{c.container.Names[0].substr('1').cyan}", (cb) ->
                tugboat.stop group, service, c, (err, result) ->
                  return cb err if err?
                  cb()
          for c in service.diff.rm
            do (c) ->
              seq "#{outputname} Deleting #{c.container.Names[0].substr('1').cyan}", (cb) ->
                tugboat.rm group, service, c, (err, result) ->
                  return cb err if err?
                  cb()
          for c in service.diff.start
            do (c) ->
              seq "#{outputname} Starting #{c.container.Names[0].substr('1').cyan}", (cb) ->
                tugboat.start group, service, c, (err, result) ->
                  return cb err if err?
                  cb()
          for c in service.diff.keep
            do (c) ->
              seq "#{outputname} Keeping #{c.container.Names[0].substr('1').cyan}", (cb) -> cb()
          
          if service.diff.create > 0
            for i in [1..service.diff.create]
              newname = "#{groupname}_#{service.name}"
              newindex = 1
              newindex++ while service.containers
                .filter (c) -> c.index is newindex.toString()
                .length isnt 0
              newname += "_#{newindex}"
              seq "#{outputname} Creating #{newname.cyan} (#{service.service.params.Image})", (cb) ->
                tugboat.up group, service, newname, (err) ->
                  return cb err if err?
                  cb()
      
      seq (cb) ->
        console.log()
        cb()