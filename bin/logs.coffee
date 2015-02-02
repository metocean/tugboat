seq = require '../src/seq'
init_errors = require './errors'
modem = require 'ducke-modem'

module.exports = (tugboat, groupname, servicenames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    
    console.log()
    if Object.keys(tugboat._groups).length is 0
      console.error '  There are no groups defined in this directory'.red
      console.error()
      process.exit 1
    
    tugboat.ps (err, groups) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      groupname = groupname.replace '.yml', ''
      if !groups[groupname]?
        console.error "  The group '#{groupname}' is not available in this directory".red
        console.error()
        process.exit 1
      
      g = groups[groupname]
      
      servicestoprocess = []
      if servicenames.length isnt 0
        haderror = no
        for name in servicenames
          if !g.services[name]?
            console.error "  The service '#{name}' is not available in the group '#{g.name}'".red
            haderror = yes
          else
            servicestoprocess.push g.services[name]
        if haderror
          process.exit 1
      else
        servicestoprocess.push service for _, service of g.services
      
      servicenames = servicestoprocess
        .map (s) -> s.name
        .join ', '
      console.log "  Listening to #{g.name.blue} (#{servicenames})..."
      console.log()
      
      # probably going to be a lot of listeners
      process.stdout.setMaxListeners 60
      process.stderr.setMaxListeners 60
      for s in servicestoprocess
        for c in s.containers
          tugboat.ducke
            .container c.container.Id
            .logs (err, stream) ->
              return console.error err if err?
              modem.DemuxStream stream, process.stdout, process.stderr