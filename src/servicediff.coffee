identifyprimary = (service) ->
  #if service.isknown
  keep: []
  discard: service.containers

servicediff = (group, service) ->
  # If we don't know the service the best we can do is start anything that is stopped
  # TODO: Compare images and restart if newer image--- by coping all settings? Perhaps...
  if !service.isknown
    return {
      stop: []
      rm: []
      start: service.containers.filter (c) ->
        !c.inspect.State.Running
      create: no
    }
  
  { keep, discard } = identifyprimary service
  
  result =
    stop: []
    rm: []
    start: []
    create: 0
  
  for k in keep
    result.start.push k if !k.inspect.State.Running
  for d in discard
    result.stop.push d if d.inspect.State.Running
    result.rm.push d
  result.create++ while result.create + keep.length < 1
  
  console.log group.name
  console.log "  stop: #{result.stop.length}"
  console.log "  rm: #{result.rm.length}"
  console.log "  start: #{result.start.length}"
  console.log "  create: #{result.create}"
  
  result

module.exports = (groups) ->
  for _, g of groups
    for _, s of g.services
      s.diff = servicediff g, s
  
  groups