init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, results) ->
      if err?
        if err.stack then console.error err.stack
        else console.error err
        return
      
      console.log()
      console.log "  Diff of #{groupname.blue}:"
      console.log()
      
      for _, service of results[groupname].services
        outputname = service.name.blue
        outputname += ' ' while outputname.length < 36
        
        if service.diff.iserror
          console.error "  #{outputname} #{'Error:'.red}"
          for m in service.diff.messages
            console.log "  #{outputname} #{m}"
          continue
        
        for m in service.diff.messages
          console.log "  #{outputname} #{m}"
        for c in service.diff.stop
          console.log "  #{outputname} Stopping #{c.container.Names[0].substr('1').green}"
        for c in service.diff.rm
          console.log "  #{outputname} Deleting #{c.container.Names[0].substr('1').green}"
        for c in service.diff.start
          console.log "  #{outputname} Starting #{c.container.Names[0].substr('1').green}"
        for c in service.diff.keep
          console.log "  #{outputname} Keeping #{c.container.Names[0].substr('1').green}"
        if service.diff.create is 1
          console.log "  #{outputname} Creating a new container"
        else if service.diff.create > 1
          console.log "  #{outputname} Creating #{service.diff.create.toString().green} new containers"
      
      console.log()