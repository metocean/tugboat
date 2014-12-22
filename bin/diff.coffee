init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, results) ->
      return console.err if err?
      
      console.log()
      console.log "  Diff of #{groupname.blue}:"
      console.log()
      
      for _, service of results[groupname].services
        console.log "  #{service.name.cyan}:"
        
        if service.diff.iserror
          console.error "  Error:".red
          for m in service.diff.messages
            console.log "  #{m}"
          continue
        
        for m in service.diff.messages
          console.log "    #{m}"
        for c in service.diff.stop
          console.log "    Stopping #{c.container.Names[0].substr('1').green}"
        for c in service.diff.rm
          console.log "    Deleting #{c.container.Names[0].substr('1').green}"
        for c in service.diff.start
          console.log "    Starting #{c.container.Names[0].substr('1').green}"
        for c in service.diff.keep
          console.log "    Keeping #{c.container.Names[0].substr('1').green}"
        if service.diff.create is 1
          console.log "    Creating a new container"
        else if service.diff.create > 1
          console.log "    Creating #{service.diff.create.toString().green} new containers"
        console.log()
      
      console.log()