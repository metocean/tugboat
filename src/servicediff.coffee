containerdiff = require './containerdiff'

identifyprimary = (service, imagerepo) ->
  # Locate the image we should be using
  tagname = service.service.params.Image
  tagname += ':latest' if tagname.indexOf(':') is -1
  if !imagerepo.tags[tagname]?
    return {
      messages: ["Image '#{service.service.params.Image}' not found"]
      error: service.containers
      iserror: yes
      keep: []
      migrate: []
      cull: []
    }
  
  image = imagerepo.tags[tagname]
  
  result =
    messages: []
    error: []
    iserror: no
    keep: []
    migrate: []
    cull: []
  
  for c in service.containers
    if result.keep.length isnt 0
      result.cull.push c
      continue
    
    difference = containerdiff c, service, image
    
    if !difference?
      result.keep.push c
    else
      result.messages.push difference
      result.migrate.push c
  
  result

servicediff = (group, service, imagerepo) ->
  result =
    messages: []
    error: []
    iserror: no
    keep: []
    migrate: []
    cull: []
    create: 0
  
  if !service.isknown
    result.messages.push 'Unknown service.'
    return result
  
  { messages, error, iserror, keep, migrate, cull } = identifyprimary service, imagerepo
  
  for m in messages
    result.messages.push m
  for e in error
    result.error.push e
  result.iserror = iserror
  for k in keep
    if !k.inspect.State.Running
      result.start.push k
    else
      result.keep.push k
  for m in migrate
    result.migrate.push m
  for d in cull
    result.cull.push d
  
  if !result.iserror
    result.create++ while result.create + keep.length + migrate.length < 1
  result

module.exports = (imagerepo, groups) ->
  for _, g of groups
    for _, s of g.services
      s.diff = servicediff g, s, imagerepo
  groups