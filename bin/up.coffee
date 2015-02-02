seq = require '../src/seq'
init_errors = require './errors'
output_error = require './output_error'
logs = require './logs'

cname = (c) -> c.container.Names[0].substr '1'

module.exports = (tugboat, groupname, servicenames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, results) ->
      return output_error err if err?
      
      groupname = groupname.replace '.yml', ''
      
      console.log()
      console.log "  Updating #{groupname.blue}..."
      console.log()
      
      group = results[groupname]
      
      for _, service of group.services
        do (service) ->
          outputname = service.name
          outputname += ' ' while outputname.length < 32
          outputname = outputname.cyan
          
          if service.service?
            outputname = service.service.pname.cyan
          
          seq (cb) ->
            if service.diff.iserror
              return cb service.diff.messages
            for m in service.diff.messages
              console.log "  #{outputname} #{m.magenta}"
            cb()
          
          for c in service.diff.cull
            do (c) ->
              seq "#{outputname} Culling #{cname(c).cyan}", (cb) ->
                tugboat.cull group, service, c, (err, result) ->
                  return cb err if err?
                  cb()
          for c in service.diff.migrate
            do (c) ->
              seq "#{outputname} Migrating #{cname(c).cyan}", (cb) ->
                tugboat.migrate group, service, c, (err, result) ->
                  return cb err if err?
                  cb()
          for c in service.diff.keep
            do (c) ->
              seq "#{outputname} Keeping #{cname(c).cyan}", (cb) ->
                tugboat.keep group, service, c, (err, result) ->
                  return cb err if err?
                  cb()
          if service.diff.create > 0
            for i in [1..service.diff.create]
              seq (cb) ->
                tugboat.create group, service, (err, name) ->
                  return cb err if err?
                  console.log "  #{outputname} Container #{name.cyan} created from #{service.service.params.Image}"
                  cb()
      
      seq (cb) ->
        logs tugboat, groupname, servicenames
        cb()