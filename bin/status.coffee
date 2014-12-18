init_errors = require './errors'

# Pluralise function
ess = (num, s, p) -> if num is 1 then s else p

module.exports = (tugboat) ->
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