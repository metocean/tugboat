series = require '../src/series'
init_errors = require './errors'

module.exports = (tugboat, groupnames, usecache) ->
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
    
    groupnames = groupnames.map (g) -> g.replace '.yml', ''
    
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
          console.log()
          for servicename, config of group.services
            do (servicename, config) ->
              output = servicename.cyan
              # Build each group, build each service
              grouptasks.push (cb) ->
                output += ' ' while output.length < 36
                process.stdout.write "  #{output} "
                
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
                    console.error 'X'.red
                    console.error err
                    console.error results if results.length isnt 0
                    console.error()
                    return cb()
                  console.log '√'.green
                  cb()
          
          series grouptasks, ->
            console.log()
            cb()
    
    series tasks, ->