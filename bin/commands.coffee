require 'colors'

series = (tasks, callback) ->
  tasks = tasks.slice 0
  next = (cb) ->
    return cb() if tasks.length is 0
    task = tasks.shift()
    task -> next cb
  result = (cb) -> next cb
  result(callback) if callback?
  result

ess = (num, s, p) -> if num is 1 then s else p

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


build = (tugboat, names, usecache) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    console.log()
    if Object.keys(tugboat._groups).length is 0
      console.error '  There are no groups defined in this directory'.magenta
      console.error()
      process.exit 1
    
    if names.length is 0
      names = Object.keys tugboat._groups
    
    haderror = no
    for name in names
      if !tugboat._groups[name]?
        console.error "  The group '#{name}' is not available in this directory".red
        console.error()
        haderror = yes
    if haderror
      process.exit 1
    
    tasks = []
    
    for name in names
      group = tugboat._groups[name]
      do (group) ->
        tasks.push (cb) ->
          grouptasks = []
          console.log "  Building #{name.blue}..."
          for container, config of group.containers
            do (container, config) ->
              output = container.cyan
              grouptasks.push (cb) ->
                output += ' ' while output.length < 32
                process.stdout.write "    #{output} "
                
                if !config.build?
                  console.log '-'.magenta
                  return cb()
                
                results = ''
                run = (message) ->
                  results += message
                  results += '\n'
                
                tugboat.build group, container, usecache, run, (err) ->
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
  
  ps: (tugboat, names) ->
    tugboat.init (errors) ->
      return init_errors errors if errors?
      
      tugboat.ps (err, groups) ->
        if Object.keys(groups).length is 0
          console.log()
          console.log '  There are no groups defined in this directory or containers running that match'.magenta
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
            name = group.name
            name += ' ' while name.length < 28
            name = name.blue
            
            postfix = ''
            postfix += ' (unknown)'.magenta if !group.isknown
            
            total = 0
            created = 0
            running = 0
            for _, container of group.containers
              total++
              if container.indexes.length isnt 0
                created++
                r = container.indexes
                  .filter (d) -> d.inspect.State.Running
                  .length
                running++ if r isnt 0
            
            if running is total
              console.log "  #{name} #{"#{total} up".green}#{postfix}"
              continue
            
            if created is 0
              console.log "  #{name} #{"#{total} uncreated".magenta}#{postfix}"
              continue
            
            if created is total and running is 0
              console.log "  #{name} #{"#{total} stopped".red}#{postfix}"
              continue
            
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
          
          for _, container of group.containers
            containername = container.name.cyan
            for i in container.indexes
              containername += " #{i.index}"
            containername += ' ' while containername.length < 36
            
            status = '-'.magenta
            
            if container.indexes.length > 0
              r = container.indexes
                .filter (d) -> d.inspect.State.Running
                .length
              if r is 0
                status = 'stopped'.red
              else
                status = container.indexes[0].inspect.NetworkSettings.IPAddress.toString().blue
            
            console.log "    #{containername} #{status}"
            continue
          console.log()
  
  build: (tugboat, names) ->
    build tugboat, names, yes
  
  rebuild: (tugboat, names) ->
    build tugboat, names, no