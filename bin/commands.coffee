require 'colors'

# Run things one after another - better for human reading
series = (tasks, callback) ->
  tasks = tasks.slice 0
  next = (cb) ->
    return cb() if tasks.length is 0
    task = tasks.shift()
    task -> next cb
  result = (cb) -> next cb
  result(callback) if callback?
  result

# Pluralise function
ess = (num, s, p) -> if num is 1 then s else p

# General purpose error reporting
init_errors = (errors) ->
  for e in errors
    console.error()
    console.error "  #{e.path}".red
    for err, index in e.errors
      if !err.name?
        console.error err
        continue
      if err.name is 'YAMLException'
        console.error "  #{index + 1}) #{e.path}:#{err.mark.line + 1}"
        console.error err.message
      else if err.name is 'TUGBOATFormatException'
        console.error "  #{index + 1}) #{err.message}"
      else
        console.error "  #{index + 1}) Unknown error:"
        console.error err
  console.error()
  process.exit 1

# Build is here so we can adjust the cache
build = (tugboat, groupnames, usecache) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    console.log()
    if Object.keys(tugboat._groups).length is 0
      console.error '  There are no groups defined in this directory'.magenta
      console.error()
      process.exit 1
    
    # Build everything if no group names are passed
    if groupnames.length is 0
      groupnames = Object.keys tugboat._groups
    
    haderror = no
    for name in groupnames
      if !tugboat._groups[name]?
        console.error "  The group '#{name}' is not available in this directory".red
        console.error()
        haderror = yes
    if haderror
      process.exit 1
    
    tasks = []
    
    for name in groupnames
      group = tugboat._groups[name]
      # Capture variables
      do (name, group) ->
        tasks.push (cb) ->
          grouptasks = []
          console.log "  Building #{name.blue}..."
          for servicename, config of group.services
            do (servicename, config) ->
              output = servicename.cyan
              # Build each group, build each service
              grouptasks.push (cb) ->
                output += ' ' while output.length < 32
                process.stdout.write "    #{output} "
                
                # Skip services that are based on images
                if !config.build?
                  console.log '-'.magenta
                  return cb()
                
                # Record results incase of error
                results = ''
                run = (message) ->
                  results += message
                  results += '\n'
                
                tugboat.build group, servicename, usecache, run, (err) ->
                  if err?
                    console.error 'failed'.red
                    console.error err
                    console.error results if results.length isnt 0
                    console.error()
                    return cb()
                  console.log 'done'.green
                  cb()
          
          series grouptasks, ->
            console.log()
            cb()
    
    series tasks, ->

up = (tugboat, groupname, servicenames, isdryrun) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    console.log()
    if Object.keys(tugboat._groups).length is 0
      console.error '  There are no groups defined in this directory'.red
      console.error()
      process.exit 1
    
    if !tugboat._groups[groupname]?
      console.error "  The group '#{groupname}' is not available in this directory".red
      console.error()
      process.exit 1
    
    group = tugboat._groups[groupname]
    
    if servicenames.length is 0
      servicenames = Object.keys group.services
    
    haderror = no
    for name in servicenames
      if !group.services[name]?
        console.error "  The service '#{name}' is not available in the group '#{groupname}'".red
        console.error()
        haderror = yes
    if haderror
      process.exit 1
    
    tugboat.ducke.ls (err, imagerepo) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      tugboat.ps (err, groups) ->
        if err?
          console.error()
          console.error '  docker is down'.red
          console.error()
          process.exit 1
        
        g = groups[groupname]
        
        tasks = []
        if isdryrun
          console.log "  Dry run for #{groupname.blue}..."
        else
          console.log "  Starting #{groupname.blue}..."
        console.log()
        for servicename in servicenames
          do (servicename) ->
            tasks.push (cb) ->
              service = g.services[servicename]
              s = g.services[servicename]
              
              outputname = servicename
              outputname += ' ' while outputname.length < 18
              
              imagename = "#{groupname}_#{servicename}"
              if service.service.image?
                imagename = service.service.image
              
              if imagename.indexOf ':' is -1
                imagename += ':latest'
              
              if !imagerepo.tags[imagename]?
                console.error "  #{outputname.blue} image #{imagename.red} is not available"
                console.error()
                return cb()
              image = imagerepo.tags[imagename]
              
              primary = null
              excess = []
              
              for c in s.containers
                if image.image.Id is c.inspect.Image
                  primary = c
                else
                  console.log "  #{outputname.blue} image #{image.image.Id.substr(0, 12).cyan} is newer than #{c.inspect.Image.substr(0, 12).cyan}"
                  excess.push c
              
              for e in excess
                name = e.container.Names[0].substr 1
                if e.inspect.State.Running
                  console.log "  #{outputname.blue} stopping old container #{name.cyan}"
                  
                console.log "  #{outputname.blue} removing old container #{name.cyan}"
              
              if primary?
                name = primary.container.Names[0].substr 1
                if primary.inspect.State.Running
                  console.log "  #{outputname.blue} container #{name.cyan} already #{'running'.green}"
                else
                  console.log "  #{outputname.blue} starting existing container #{name.cyan}"
              else
                console.log "  #{outputname.blue} creating new container from #{imagename.cyan}"
              
              return cb() if isdryrun?
              
              console.log 'WOULD BE DOING IT HERE'
              cb()
        
        series tasks, ->
          console.log()

module.exports =
  status: (tugboat) ->
    tugboat.init (errors) ->
      return init_errors errors if errors?
      
      count = Object.keys(tugboat._groups).length
      console.log()
      if count is 0
        console.log '  There are no groups defined in this directory'.magenta
      else
        console.log "  There are #{count.toString().green} group #{ess count, 'definition', 'definitions'} in this directory"
      
      tugboat.ducke.ping (err, isUp) ->
        if err? or !isUp
          console.error()
          console.error '  docker is down'.red
          console.error()
          process.exit 1
        else
          tugboat.ducke.ps (err, results) ->
            if err? or results.length is 0
              console.error()
              console.error '  There are no docker containers on this system'.magenta
              console.error()
            else
              running = results
                .filter (d) -> d.inspect.State.Running
                .length
              stopped = results.length - running
              console.error()
              console.error "  There #{ess running, 'is', 'are'} #{running.toString().green} running container#{ess running, '', 's'} and #{stopped.toString().red} stopped container#{ess stopped, '', 's'}"
              console.error()
            process.exit 1
  
  diff: (tugboat, groupname, servicenames) ->
    up tugboat, groupname, servicenames, yes
  
  up: (tugboat, groupname, servicenames) ->
    up tugboat, groupname, servicenames, no
  
  ps: (tugboat, names) ->
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
          console.log '  There are no groups defined in this directory'
          console.log '  or running containers that match known services'.magenta
          console.log()
          return
          
        if err?
          console.error()
          console.error '  docker is down'.red
          console.error()
          process.exit 1
        
        if names.length is 0
          console.log()
          for _, group of groups
            name = group.name.blue
            name += ' ' while name.length < 28
            
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
              output += "#{total - created}".magenta
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
            console.log "  #{group.name.blue}:"
          else
            console.log "  #{group.name.blue}: #{'(unknown)'.magenta}"
          
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
            
            console.log "    #{servicename} #{status}"
            continue
          console.log()
  
  # These are just different cache options for the same build function
  build: (tugboat, names) -> build tugboat, names, yes
  rebuild: (tugboat, names) -> build tugboat, names, no