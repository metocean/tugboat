seq = require '../src/seq'
init_errors = require './errors'

module.exports = (tugboat, groupname, servicename, cmd) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, groups) ->
      if err?
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      
      console.log()
      groupname = groupname.replace '.yml', ''
      if !groups[groupname]?
        console.error "  The group '#{groupname}' is not available in this directory".red
        console.error()
        process.exit 1
      
      g = groups[groupname]
      
      if !g.services[servicename]?
        console.error "  #{groupname} #{servicename} is not available".red
        console.error()
        process.exit 1
      
      s = g.services[servicename]
      
      if s.containers.length is 0
        console.error "  #{groupname} #{servicename} is not running".red
        console.error()
        process.exit 1
      
      if s.containers.length > 1
        console.error "  #{groupname} #{servicename} too many containers running".red
        console.error()
        process.exit 1
      
      console.log "  #{'exec'.green} #{groupname} #{servicename} (#{s.containers[0].inspect.Config.Image})"
      console.log()
      
      cmd = ['bash'] if !cmd? or cmd.length is 0
      tugboat.ducke
        .container s.containers[0].container.Id
        .exec cmd, process.stdin, process.stdout, process.stderr, (err, code) ->
          return process.exit 1 if err?
          process.exit code