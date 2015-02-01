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
      console.log "  Diff of #{groupname.blue}:"
      console.log()
      
      for _, service of results[groupname].services
        outputname = service.name
        outputname += ' ' while outputname.length < 32
        outputname = outputname.cyan
        
        if service.service?
          outputname = service.service.pname.cyan
        
        if service.diff.iserror
          console.error "  #{outputname} #{'Error:'.red}"
          for m in service.diff.messages
            console.log "  #{outputname} #{m.red}"
          continue
        for m in service.diff.messages
          console.log "  #{outputname} #{m.magenta}"
        
        cname = (c) -> c.container.Names[0].substr('1').cyan
        for c in service.diff.cull
          console.log "  #{outputname} Culling #{cname(c)}"
        for c in service.diff.migrate
          console.log "  #{outputname} Migrating #{cname(c)}"
        for c in service.diff.keep
          console.log "  #{outputname} Keeping #{cname(c)}"
        if service.diff.create is 1
          console.log "  #{outputname} Creating a new container from #{service.service.params.Image}"
        else if service.diff.create > 1
          console.log "  #{outputname} Creating #{service.diff.create.toString().green} new containers"
      
      console.log()