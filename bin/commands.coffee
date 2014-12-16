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

module.exports =
  status: (tugboat) ->
    tugboat.init (errors) ->
      return init_errors errors if errors?
      
      count = Object.keys(tugboat._groups).length
      console.log()
      if count is 0
        console.log '  There are no groups defined in this directory'.magenta
      else
        console.log "  #{count.toString().green} group #{ess count, 'definition', 'definitions'} available."
      
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
  
  build: (tugboat, names) ->
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
                  
                  tugboat.build group, container, run, (err) ->
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
  
  ls: (tugboat, names) ->
    tugboat.init (errors) ->
      return init_errors errors if errors?
      
      console.log()
      if Object.keys(tugboat._groups).length is 0
        console.log '  There are no groups defined in this directory'.magenta
        console.log()
        return
      
      if names.length is 0
        for name, group of tugboat._groups
          name += ' ' while name.length < 26
          count = Object.keys(group.containers).length
          console.log "  #{name.blue} #{count.toString().green} container#{ess count, '', 's'} defined in group"
        console.log()
        return
      
      for name in names
        if !tugboat._groups[name]?
          console.error "  The group '#{name}' is not available in this directory".red
          console.error()
          continue
        
        group = tugboat._groups[name]
        
        if Object.keys(group.containers).length is 0
          console.log "  #{name.blue}"
          console.log '    No containers defined in group'.magenta
          console.log()
          
        else
          console.log "  #{name.blue}:"
          
          for container, _ of group.containers
            console.log "    #{container.cyan}"
          console.log()