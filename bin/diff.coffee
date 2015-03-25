init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames, callback) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, results) ->
      if err?
        if err.stack then console.error err.stack
        else console.error err
        return
      
      groupname = groupname.replace '.yml', ''
      
      if !results[groupname]?
        console.error()
        console.error "  Cannot diff #{groupname.red}, #{groupname}.yml not found in this directory"
        console.error()
        process.exit 1
      
      group = results[groupname]
      
      if !group.isknown
        console.error()
        console.error "  Cannot up #{groupname.red}, #{groupname}.yml not found in this directory"
        console.error()
        process.exit 1
      
      console.log()
      console.log "  Diff of #{groupname.blue}..."
      console.log()
      
      servicestoprocess = []
      if servicenames.length isnt 0
        haderror = no
        for name in servicenames
          if !group.services[name]?
            console.error "  The service '#{name}' is not available in the group '#{group.name}'".red
            haderror = yes
          else
            servicestoprocess.push group.services[name]
        if haderror
          process.exit 1
      else
        servicestoprocess.push service for _, service of group.services
      
      if servicestoprocess.length is 0
        seq (cb) ->
          console.log "  No services to process".magenta
          cb()
      
      for service in servicestoprocess
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
      callback() if callback?