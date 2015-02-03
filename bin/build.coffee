seq = require '../src/seq'
init_errors = require './errors'

module.exports = (tugboat, groupnames, usecache, callback) ->
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
    
    for name in groupnames
      group = tugboat._groups[name]
      # Capture variables
      do (name, group) ->
        seq (cb) ->
          seq (cb) ->
            console.log "  Building #{name.blue}..."
            console.log()
            cb()
          for servicename, config of group.services
            do (servicename, config) ->
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