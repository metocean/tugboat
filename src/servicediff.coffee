containerdiff = require './containerdiff'

identifyprimary = (service, imagerepo) ->
  if !service.isknown
    return {
      messages: ["Unknown service #{service.name}, restart everything"]
      keep: []
      discard: service.containers
      error: []
      iserror: yes
    }
  
  # Locate the image we should be using
  tagname = service.service.params.Image
  tagname += ':latest' if tagname.indexOf(':') is -1
  if !imagerepo.tags[tagname]?
    return {
      messages: ["Image '#{service.service.params.Image}' not found"]
      keep: []
      discard: []
      error: service.containers
      iserror: yes
    }
  image = imagerepo.tags[tagname]
  
  result = {
    messages: []
    keep: []
    discard: []
    error: []
    iserror: no
  }
  
  for c in service.containers
    if result.keep.length isnt 0
      result.discard.push c
      continue
    
    difference = containerdiff c, service, image
    
    if !difference?
      result.keep.push c
    else
      result.messages.push difference
      result.discard.push c
  
  result

servicediff = (group, service, imagerepo) ->
  result =
    messages: []
    stop: []
    rm: []
    start: []
    keep: []
    error: []
    create: 0
    iserror: no
  
  # If we don't know the service the best we can do is start anything that is stopped
  # TODO: Compare images and restart if newer image--- by coping all settings? Perhaps...
  if !service.isknown
    result.messages.push 'Unknown service, starting anything that is stopped.'
    result.start = service.containers.filter (c) ->
        !c.inspect.State.Running
    return result
  
  { messages, keep, discard, error, iserror } = identifyprimary service, imagerepo
  
  for k in keep
    if !k.inspect.State.Running
      result.start.push k
    else
      result.keep.push k
  for d in discard
    result.stop.push d if d.inspect.State.Running
    result.rm.push d
  for e in error
    result.error.push e
  for m in messages
    result.messages.push m
  result.iserror = iserror
  
  if !result.iserror
    result.create++ while result.create + keep.length < 1
  
  result

module.exports = (imagerepo, groups) ->
  for _, g of groups
    for _, s of g.services
      s.diff = servicediff g, s, imagerepo
  
  groups