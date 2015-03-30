seq = require '../src/seq'
init_errors = require './errors'

module.exports = (tugboat, groupname, servicenames, usecache, callback) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    console.log()
    if Object.keys(tugboat._groups).length is 0
      console.error '  There are no groups defined in this directory'.magenta
      console.error()
      process.exit 1
    
    # Build everything if no group names are passed
    groupnames =
      if !groupname?
        Object.keys tugboat._groups
      else
        [groupname.replace '.yml', '']
    
    haderror = no
    for name in groupnames
      if !tugboat._groups[name]?
        console.error "  The group '#{name}' is not available in this directory".red
        console.error()
        haderror = yes
    if haderror
      process.exit 1
    
    for name in groupnames
      group = tugboat._groups[name]
      # Capture variables
      do (name, group) ->
        seq (cb) ->
          seq (cb) ->
            console.log "  Building #{name.blue}..."
            console.log()
            cb()
          
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
          
          for config in servicestoprocess
            do (config) ->
              return if !config.build?
              # Build each group, build each service
              seq "#{config.pname.cyan}", (cb) ->
                # Record results incase of error
                results = ''
                run = (message) ->
                  results += message
                  results += '\n'
                
                tugboat.build group, config, usecache, run, (err) ->
                  if err?
                    console.error results if results.length isnt 0
                    return cb err
                  cb()
          
          seq (cb) ->
            console.log()
            cb()
          
          cb()
    
    seq (cb) ->
      cb()
      callback if callback?