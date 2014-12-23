series = require '../src/series'
init_errors = require './errors'

module.exports = (tugboat, groupnames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    console.log()
    if Object.keys(tugboat._groups).length is 0
      console.error '  There are no groups defined in this directory'.magenta
      console.error()
      process.exit 1
    
    # Pull everything if no group names are passed
    if groupnames.length is 0
      groupnames = Object.keys tugboat._groups
    
    haderror = no
    for groupname in groupnames
      if !tugboat._groups[groupname]?
        console.error "  The group '#{groupname}' is not available in this directory".red
        console.error()
        haderror = yes
    if haderror
      process.exit 1
    
    tugboat.ducke.ls (err, images) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      console.log images.tags['phusion/baseimage:0.9.15']
      
      tasks = []
      
      for groupname in groupnames
        group = tugboat._groups[groupname]
        do (groupname, group) ->
          tasks.push (cb) ->
            console.log "  Pulling images for #{groupname.blue}..."
            console.log()
            cb()
          
          for servicename, config of group.services
            do (servicename, config) ->
              tasks.push (cb) ->
                output = servicename.cyan
                output += ' ' while output.length < 32
                console.log "  #{output} Pulling #{config.params.Image.cyan}"
                cb()
          
          tasks.push (cb) ->
            console.log()
            cb()
      
      series tasks, ->