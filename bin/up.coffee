seq = require '../src/seq'
init_errors = require './errors'
output_error = require './output_error'
logs = require './logs'
toposort = require 'toposort'

cname = (c) -> c.container.Names[0].substr '1'

# Converts a container name (#{groupname}_#{service_name}_1) to just
# the service name
containter_name_to_service_name = (container_name, groupname) ->
  re = RegExp '^' + groupname + '_'
  service_name = container_name.replace(re, '')
  service_name = service_name.replace(/_1$/, '')
  return service_name

# Returns an array of services sorted by dependency
get_sorted_services = (services, servicenames, groupname) ->
  if servicenames?
    servicenames = Object.keys(services)

  # Build list of links
  edges = []
  for name, service of services
    if name in servicenames and service.service.params.HostConfig.Links?
      for link in service.service.params.HostConfig.Links
        container_name = link.split(':')[0]
        service_name = containter_name_to_service_name container_name, groupname
        edge = [name, service_name]
        edges.push edge

  # Reverse toposort to order by dependency. Any edges that 
  # aren't in the nodes array will be ignored for sorting.
  try
    sortednames = toposort.array(servicenames, edges).reverse()
  catch error
    console.error "Service link dependency could not be resolved (#{error})"
    process.exit 1

  # Sort the services.
  sortedservices = []
  for name in sortednames
    sortedservices.push services[name]

  return sortedservices


module.exports = (tugboat, groupname, servicenames) ->
  tugboat.init (errors) ->
    return init_errors errors if errors?
    tugboat.diff (err, results) ->
      return output_error err if err?
      
      groupname = groupname.replace '.yml', ''
      
      if !results[groupname]?
        console.error()
        console.error "  Cannot up #{groupname.red}, #{groupname}.yml not found in this directory"
        console.error()
        process.exit 1
      
      group = results[groupname]
      
      if !group.isknown
        console.error()
        console.error "  Cannot up #{groupname.red}, #{groupname}.yml not found in this directory"
        console.error()
        process.exit 1
      
      console.log()
      console.log "  Updating #{groupname.blue}..."
      console.log()
      
      sname = (s) ->
        name = s.name
        name += ' ' while name.length < 32
        name = name.cyan
        if s.service?
          name = s.service.pname.cyan
        name
      
      # Build valid list of service names
      if servicenames.length isnt 0
        haderror = no
        for name in servicenames
          if !group.services[name]?
            console.error "  The service '#{name}' is not available in the group '#{group.name}'".red
            haderror = yes
        if haderror
          process.exit 1
      else
        servicenames = name for name, _ of group.services

      servicestoprocess = get_sorted_services group.services, servicenames, groupname
      
      if servicestoprocess.length is 0
        seq (cb) ->
          console.log "  No services to process".magenta
          cb()
      
      for service in servicestoprocess
        do (service) ->
          outputname = sname service
          
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
      
      for service in servicestoprocess
        do (service) ->
          outputname = sname service
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
        console.log()
        # logs tugboat, groupname, servicenames
        cb()