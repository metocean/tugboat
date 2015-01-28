series = require '../src/series'
init_errors = require './errors'

module.exports = (tugboat, names) ->
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
      
      names = names.map (g) -> g.replace '.yml', ''
      if names.length is 0
        console.log()
        for _, group of groups
          name = group.name.blue
          name += ' ' while name.length < 36
          
          # We discover groups by parsing active docker container names
          # These might not be detailed in group yaml files
          # so we identify this with the label (unknown)
          postfix = ''
          postfix += ' (unknown)'.magenta if !group.isknown
          
          total = 0
          created = 0
          running = 0
          for _, service of group.services
            total++
            if service.containers.length isnt 0
              created++
              r = service.containers
                .filter (d) -> d.inspect.State.Running
                .length
              running++ if r is service.containers.length
          
          # If every service is running
          if running is total
            console.log "  #{name} #{"#{total} up".green}#{postfix}"
            continue
          
          # If no services have been created
          if created is 0
            console.log "  #{name} #{"#{total} uncreated".magenta}#{postfix}"
            continue
          
          # If all services are stopped
          if created is total and running is 0
            console.log "  #{name} #{"#{total} stopped".red}#{postfix}"
            continue
          
          # Incrementally build a description of each state
          output = "  #{name}"
          if running > 0
            output += " #{running.toString().green}"
            output += ' running'
          
          if created - running > 0
            output += " #{created - running}".red
            output += ' stopped'
          
          if total - created > 0
            output += " #{total - created}".magenta
            output += ' uncreated'
          
          output += postfix
          console.log output
        console.log()
        return
      
      console.log()
      for name in names
        if !groups[name]?
          console.error "  The group '#{name}' is not available in this directory".red
          console.error "  and has no created containers".red
          console.error()
          continue
        
        group = groups[name]
        if group.isknown
          console.log "  #{group.name.blue} services:"
        else
          console.log "  #{group.name.blue} services: #{'(unknown)'.magenta}"
        console.log()
        
        for _, service of group.services
          servicename = service.name.cyan
          for i in service.containers
            servicename += " #{i.index}"
          servicename += ' ' while servicename.length < 36
          
          # Calculate a status for each service
          status = '-'.magenta
          if service.containers.length > 0
            r = service.containers
              .filter (d) -> d.inspect.State.Running
              .length
            if r isnt service.containers.length
              status = 'stopped'.red
            else
              # There might be multiple containers
              status = service.containers
                .map (c) -> c.inspect.NetworkSettings.IPAddress.toString().blue
                .join ', '
          status += ' (unknown)'.magenta if !service.isknown
          
          console.log "  #{servicename} #{status}"
          continue
        console.log()